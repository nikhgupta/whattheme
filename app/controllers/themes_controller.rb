require 'nokogiri'
require 'open-uri'
require 'uri'
require 'cgi'

class ThemesController < ApplicationController

  respond_to :json

  def discover
    begin
      @theme = discover_wp_theme params[:url]
    rescue Exception => e
      @theme = { "success" => false, "message" => "Encountered an error: #{e.to_s}" }
    end
    render_json @theme, params
  end

  def index
    @themes = Theme.all
    render_json @themes, params
  end

  def show
    @theme = Theme.find(params[:id])
    render_json @theme, params
  end

  def edit
    @theme = Theme.find(params[:id])
    render_json @theme, params
  end

  def create
    @theme = Theme.new(params[:theme])
    render_json @theme, params
  end

  def update
    @theme = Theme.find(params[:id])
    @theme.update_attributes(params[:theme])
    render_json @theme, params
  end

  def destroy
    @theme = Theme.find(params[:id])
    @theme.destroy
    render_json @theme, params
  end



  private
  def render_json(object, params)
    if params[:callback]
      render :json => object, :callback => params[:callback]
    else
      respond_with object
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
  def discover_wp_theme(url)
    # make sure we have a sanitized url
    url = sanitize_url url

    # use a user-agent string when using Nokogiri for fetching pages
    @myuseragent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/535.19 (KHTML, like Gecko) Chrome/18.0.1025.142 Safari/535.19"
    doc = Nokogiri::HTML(open(url, 'User-Agent' => @myuseragent))

    @info = {"success" => true, "uri" => url}
    title = doc.xpath("//title").first
    @info["title"] = title.inner_text.to_s unless title.blank?

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
      @info["code"]    = "not_wordpress"
      @info["code"]    = "customized_theme" if search_for_existence_wp url
    end
    reply_nicely_for_wordpress
  end
  # }}}
  # search for wordpress theme - main method {{{
  def search_for_wp_theme(css)
    return if css.blank?
    doc = Nokogiri::HTML(open(css)).inner_text
    match = /\/\*(.*?theme\s*name.*?:.*?)\*\//im.match(doc)
    return if match.blank?
    match.to_s.each_line do |line|
      line = line.split(':', 2).map { |x| x.strip }
      @info[line[0].gsub(' ','_').downcase] = line[1] unless line[1].blank?
    end
    @info["cms"] = "WordPress"
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
        "cms"        => "WordPress",
        "method"     => "introspection",
      })
    end
  end

  def search_for_existence_wp(sanitized_url)
    sanitized_url = URI.parse(sanitized_url)
    loginurl = "#{sanitized_url.scheme}://#{sanitized_url.host}/wp-admin"
    begin
      open loginurl, 'User-Agent' => @myuseragent
    rescue OpenURI::HTTPError => e
      return false
    rescue Exception => e
      return false
    end
    true
  end
  # }}}
  # display a nicely formatted reply - WordPress {{{
  def reply_nicely_for_wordpress
    @info['keywords'] = wp_keyword if @info["success"]
    if @info["success"]
      @info['theme_name'] = "WordPress VIP Services" if @info['theme_name'] == 'vip'
      #button   = [ "Take me to Author's Website", @info['author_uri']] if @info['author_uri']
      button   = [ "Grab this theme", @info['author_uri']] if @info['author_uri']
      #button   = [ "Take me to Theme's Website",  @info['theme_uri' ]] if @info['theme_uri']
      button   = [ "Grab this theme",  @info['theme_uri' ]] if @info['theme_uri']
      google_search = search_google_for_theme_info
      message  = "<a href='#{@info['uri']}'>#{@info['title']}</a> is using "
      message += "version #{@info['version']} of the " if @info['version']
      if @info['theme_name']
        message += "<a href='#{@info['theme_uri']}'>#{@info['theme_name']}</a> theme" if @info['theme_uri']
        message += "#{@info['theme_name']} theme" unless @info['theme_uri']
      end
      if @info['author']
        message += " created by "
        message += "<a href='#{@info['author_uri']}'>#{@info['author']}</a>" if @info['author_uri']
        message += "#{@info['author']}" unless @info['author_uri']
      end
      #message += ", and is based on #{@info['template']} template" if @info['template']
      message += ".<br/><br/>"
      #message += "The description for the theme says: #{@info['description']}.<br/><br/>" if @info['description']
      message += "<div style='position: absolute; bottom: 30px'>"
      message += "<a href='#{button[1]}' class='button green close' target='_blank'>#{button[0]}</a>" unless button.blank?
      message += "<a href='#{google_search}' class='button green close' target='_blank'>Grab this theme</a>" if button.blank? and google_search
      message += "</div>"
    else
      message  = case @info["code"]
                 when "not_wordpress"    then "Are you sure, the given site is a WordPress blog?"
                 when "customized_theme" then "Seems like this WordPress blog is using a customized theme!"
                 end
    end
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
