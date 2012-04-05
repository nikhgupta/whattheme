require 'nokogiri'
require 'open-uri'
require 'uri'
class ThemesController < ApplicationController

  respond_to :json

  def discover
    @theme = discover_wp_theme params[:url]
    respond_with @theme
  end

  def index
    @themes = Theme.all
    respond_with @themes
  end

  def show
    @theme = Theme.find(params[:id])
    respond_with @theme
  end

  def edit
    @theme = Theme.find(params[:id])
    respond_with @theme
  end

  def create
    @theme = Theme.new(params[:theme])
    respond_with @theme
  end

  def update
    @theme = Theme.find(params[:id])
    @theme.update_attributes(params[:theme])
    respond_with @theme
  end

  def destroy
    @theme = Theme.find(params[:id])
    @theme.destroy
    respond_with @theme
  end



  private

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

    # search for all CSS links on this page
    styles = doc.css('link[type="text/css"]')
    style_urls = styles.collect { |style| sanitize_url(style.attribute('href').to_s, url) }

    # if possible, find theme by looking into the contents of these CSS files
    theme_info = ""
    while theme_info.blank? and style_urls.any?
      theme_info = search_for_wp_theme style_urls.shift
    end

    # otherwise, find theme by introspecting the url for the CSS files
    theme_info = search_for_wp_theme_by_introspection styles, url if theme_info.blank?

    # if we still do not have theme information, return error state
    if theme_info.blank?
      theme_info = [ {"success" => false} ]
      if search_for_existence_wp url
        theme_info << {"code" => "customized_theme" }
      else
        theme_info << {"code" => "not_wordpress"}
      end
    end
    theme_info
  end
  # }}}

  # search for wordpress theme - main method {{{
  def search_for_wp_theme(css)
    return if css.blank?
    css = sanitize_url css
    doc = Nokogiri::HTML(open(css)).inner_text
    match = /\/\*(.*theme\s*name.*:.*)\*\//im.match(doc)
    return if match.blank?
    info = [{"success" => true}]
    match.to_s.each_line do |line|
      line = line.split(':', 2).map { |x| x.strip }
      info << { line[0].gsub(' ','_').downcase => line[1] } unless line[1].blank?
    end
    info << { "cms" => "WordPress" }
  end
  # }}}

  # search for wordpress theme - introspection method {{{
  def search_for_wp_theme_by_introspection(styles, url)
    styles.each do |style|
      css = style.attribute('href').to_s
      match = css.match(/.*\/themes\/(.*)\/.*/i)
      # return if we have a match
      next if match.blank?
      return [
        {"success"    => true },
        {"theme_name" => match[1].to_s },
        {"theme_uri"  => URI.parse(url).host },
        {"cms"        => "WordPress" },
        {"method"     => "introspection" },
      ]
    end
    nil
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
# }}}

  # get absolute url and sanitize it.
  def sanitize_url(url, relative = "")
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

  def append_scheme(url)
    return "" if url.blank?
    /^http/.match(url) ? url : "http://#{url}"
  end

end
