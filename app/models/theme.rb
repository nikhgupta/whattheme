class Theme < ActiveRecord::Base
  before_save :discover_cms

  protected

  # Discover CMS {{{
  def discover_cms
    # make sure we have a sanitized url
    url = sanitize_url self.uri

    # use a user-agent string when using Nokogiri for fetching pages
    @myuseragent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/535.19 (KHTML, like Gecko) Chrome/18.0.1025.142 Safari/535.19"
    doc = Nokogiri::HTML(open(url, 'User-Agent' => @myuseragent))

    @cms = {
      :wordpress => { :name => "WordPress", },
      :joomla    => { :name => "Joomla" },
      :drupal    => { :name => "Drupal" },
    }

    generator = doc.xpath('//meta[@name="generator"]')
    unless generator.blank?
      generator = generator.attr("content").text
      @cms.each do |key,cms|
        cms_generator_regex = Regexp.new(cms.has_key?(:generator) ? cms[:generator] : cms[:name])
        return self.discovery_method url, doc, cms if generator =~ cms_generator_regex
      end
    end

    @cms.each do |key,cms|
      cms_method = cms.has_key?(:method) ? cms[:method] : "poll_for_#{cms[:name].downcase}"
      if self.respond_to?(cms_method)
        return self.discovery_method url, doc, cms if self.method(cms_method).call(url,doc)
      end
    end

    @info = { "success" => true, "uri" => url, "cms" => "unknown" }
    title = doc.xpath("//title")
    @info["title"] = title.first.inner_text.to_s unless title.blank?
    @info['code'] = "unknown"
    @info['title'] = @info['title'][0..25] + "&hellip;" if @info['title'].length > 26
    @info['message'] = "This site is either using a low key CMS or not using a CMS at all.
    <br/>Check out some flexible  WordPress frameworks here."

    self.attributes = @info.keep_if {|key,val| self.has_attribute?(key) }
  end
  # }}}

  def discovery_method(url, doc, cms)
    cms_method = cms.has_key?(:method) ? cms[:method] : "discover_#{cms[:name].downcase}_theme"
    if self.respond_to?(cms_method)
      return self.method(cms_method).call(url, doc)
    else
      return discover_generic_theme(url,doc,cms)
    end
  end

  def discover_generic_theme(url,doc,cms)
    @info = { "success" => true, "uri" => url, "cms" => cms[:name] }
    title = doc.xpath("//title")
    @info["title"] = title.first.inner_text.to_s unless title.blank?
    @info['code'] = cms[:name].downcase
    @info['title'] = @info['title'][0..25] + "&hellip;" if @info['title'].length > 26
    @info['message'] = "This site is using #{cms[:name]} as their main CMS.<br/>
                        Check out some great #{cms[:name]} themes here."

    self.attributes = @info.keep_if {|key,val| self.has_attribute?(key) }
  end

  def poll_for_wordpress(url,doc)
    begin
      rss = doc.xpath("//link[contains(@type, 'rss')]").first.attr('href').to_s
      rss = rss.gsub(/\/comments\/feed/, "")
      rss = rss.gsub(/\/feed/, "")
      loginurl = "#{rss}/wp-admin"
      html = Nokogiri::HTML(open(loginurl, 'User-Agent' => @myuseragent))
      html.to_s.include? "wp-submit"
    rescue OpenURI::HTTPError => e
      return false
    rescue Exception => e
      return false
    end
  end
  def poll_for_joomla(url,doc)
    begin
      base = doc.xpath("//base").first.attr('href').to_s
      loginurl = "#{base}/templates/system/css/system.css"
      html = Nokogiri::HTML(open(loginurl, 'User-Agent' => @myuseragent))
      html.to_s.include? "System Messages"
    rescue OpenURI::HTTPError => e
      return false
    rescue Exception => e
      return false
    end
  end
  def poll_for_drupal(url,doc)
    begin
      html = Nokogiri::HTML(open("#{url}/misc/drupal.js", 'User-Agent' => @myuseragent))
      return true if html.to_s.include? "Drupal"
      html = Nokogiri::HTML(open("#{URI.parse(url).host}/misc/drupal.js", "User-Agent" => @myuseragent))
      return true if html.to_s.include? "Drupal"
    rescue OpenURI::HTTPError => e
      return false
    rescue Exception => e
      return false
    end
  end

  # Discover WordPress Theme {{{
  # This function discovers the theme for a given WordPress website.
  # Right now, it is custom tailored to use WordPress websites and
  # reject others. However, in practice, it should call another function
  # which first tests what kind of cms we are using and based on that
  # calls the corresponding discover sublet.
  # Also, identify wp.com : http://www.quora.com/How-to-identify-sites-that-using-WordPress-org-and-WordPress-com-hosted
  #
  # * *Args*    :
  #   - +url+ -> the url to search for the wordpress theme
  # * *Returns* :
  #   - information about the theme, if found
  # * *Raises* :
  #   - +IndeterminateError+ -> theme could not be identified
  #   - +NotWordPressError+ -> the given url is not a WordPress based url
  # Discover for WordPress theme - Process {{{
  def discover_wordpress_theme(url, doc)
    @info = {"success" => true, "uri" => url, "cms" => "WordPress" }
    title = doc.xpath("//title")
    @info["title"] = title.first.inner_text.to_s unless title.blank?

    # search for all CSS links on this page
    styles = doc.css('link[type="text/css"]')
    style_urls = styles.collect { |style| sanitize_url(style.attribute('href').to_s, url) }

    # if possible, find theme by looking into the contents of these CSS files
    while !wp_theme_found? and style_urls.any?
      search_for_wp_theme sanitize_url(style_urls.shift)
    end

    # otherwise, find theme by introspecting the url for the CSS files
    search_for_wp_theme_by_introspection(styles, url) unless wp_theme_found?

    # if we still do not have theme information, return error state
    unless wp_theme_found?
      @info["success"] = false
      @info["code"]    = "customized_theme"
    end

    # make some more changes on the final results we are getting from automated methods
    @info['title'] = @info['title'][0..25] + "&hellip;" if @info['title'].length > 26
    @info['keywords'] = wp_keyword if @info["success"]

    reply_nicely_for_wordpress

    self.attributes = @info.keep_if {|key,val| self.has_attribute?(key) }
  end
  # }}}
  # search for wordpress theme - main method {{{
  def search_for_wp_theme(css)
    return if css.blank?
    begin
      doc = Nokogiri::HTML(open(css)).inner_text
    rescue
      doc = ""
    end
    match = /\/\*(.*?theme\s*name.*?:.*?)\*\//im.match(doc)
    return if match.blank?
    match.to_s.each_line do |line|
      line = line.split(':', 2).map { |x| x.strip }
      @info[line[0].gsub(' ','_').downcase] = line[1] unless line[1].blank?
    end
  end
  # }}}
  # search for wordpress theme - introspection method {{{
  def search_for_wp_theme_by_introspection(styles, url)
    styles.each do |style|
      css = style.attribute('href').to_s
      match = css.match(/.*\/wp-content\/themes\/(.*?)\/.*/i)
      # return if we have a match
      next if match.blank?
      @info.merge!({
        "success"    => true,
        "theme_name" => match[1].to_s,
        "method"     => "introspection",
      })
    end
  end

  # }}}
  # display a nicely formatted reply - WordPress {{{
  def reply_nicely_for_wordpress
    if @info["success"]
      google_search = search_google_for_theme_info
      button   = [ "Grab this theme", @info['author_uri']] if @info['author_uri']
      button   = [ "Grab this theme", @info['theme_uri' ]] if @info['theme_uri']
      button   = [ "Grab this theme", google_search ] if button.blank? and google_search
      message  = "This site is using the "
      #message  = "<a href='#{@info['uri']}'>#{@info['title']}</a> is using "
      #message += "version #{@info['version']} of the " if @info['version']
      if @info['theme_name']
        @info['theme_name'] = "WordPress VIP Services" if @info['theme_name'] == 'vip'
        if @info['theme_name'] == "vip"
          message += "<a href='http://vip.wordpress.com/'>WordPress VIP Services"
        else
          if @info['theme_uri']
            message += "<a href='#{@info['theme_uri']}'>#{@info['theme_name']}</a> theme"
          elsif (!@info.has_key?('author_uri') or @info['author_uri'].blank?) and google_search.blank?
            message += "<a href='#{google_search}'>#{@info['theme_name']}</a> theme"
          elsif (!@info.has_key?('theme_uri') and @info['theme_uri'].blank?)
            message += "#{@info['theme_name']} theme"
          end
        end
      end
      if @info['author']
        message += " created by "
        message += "<a href='#{@info['author_uri']}'>#{@info['author']}</a>" if @info['author_uri']
        message += "#{@info['author']}" unless @info['author_uri']
      end
      #message += ", and is based on #{@info['template']} template" if @info['template']
      message += ".<br/><br/>"
      #message += "The description for the theme says: #{@info['description']}.<br/><br/>" if @info['description']
    else
      message  = case @info["code"]
                 when "not_wordpress"    then "Looks like this site is not using a CMS."
                 when "customized_theme" then "Looks like this site is using a customized WordPress theme. Here are some flexible WP frameworks you can build your own theme on."
                 end
    end
    message += "<div style='position: absolute; bottom: 30px'>"
    message += "<a href='#{button[1]}' class='button green close' target='_blank'>#{button[0]}</a><br/>" unless button.blank?
    message += "<small>we're in beta. if you find any errors email whattheme@5minutes.to</small>"
    message += "</div>"
    @info.merge!({"message" => message})
  end
  # }}}
  # generate a keyword to search by {{{
  def wp_keyword
    keyword  = ""
    keyword += "#{@info['template']} " if @info['template']
    keyword += "#{@info['author']} " if @info['author']
    keyword  = "wordpress themes #{keyword}#{@info['theme_name']}"
  end
  # }}}
  # know if a wordpress theme has been found {{{
  def wp_theme_found?
    @info.has_key?("theme_name")
  end
  # }}}
# }}}

  # global helpers {{{
    # get absolute url and sanitize it. {{{
    def sanitize_url(url, relative = "")
      url = url.split('?', 2)
      if url.count > 1
         url = url.first + '?' + CGI::escape(url.last)
      else
        url = url.first
      end
      return "http:#{url}" if /^\/\//.match(url)
      if !relative.blank? and URI.parse(url).host.nil?
        # get the hostname for the relative url (host which is being queried for)
        relative = append_scheme(relative)
        host = URI.parse(relative).host
        # prepend url if we have a relative url
        url = /^\//.match(url) ? host + url : relative + "/" + url
      end
      # prepend scheme if it is missing one.. use URI class?
      append_scheme url
    end
    # }}}
    # append URL Scheme to any given URL if none found {{{
    def append_scheme(url)
      return "" if url.blank?
      /^http/.match(url) ? url : "http://#{url}"
    end
    # }}}
    # search google for keyword {{{
    def search_google_for_theme_info
      return if @info['keywords'].blank?
      url = "http://www.google.com/search?q=#{CGI::escape(@info['keywords'].gsub(' ','+'))}"
      doc = Nokogiri::HTML(open(url))
      url = doc.css("#ires .g .r a").first.attribute('href').to_s
      params = CGI::parse URI.parse(url).query
      params["q"].first
    end
    # }}}
  # }}}

end
