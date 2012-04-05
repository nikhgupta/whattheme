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
    myuseragent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/535.19 (KHTML, like Gecko) Chrome/18.0.1025.142 Safari/535.19"
    doc = Nokogiri::HTML(open(url, 'User-Agent' => myuseragent))

    # search for all CSS links on this page
    styles = doc.css('link[type="text/css"]')
    style_urls = styles.collect { |style| sanitize_url(style.attribute('href').to_s, url) }

    # if possible, find theme by looking into the contents of these CSS files
    theme_info = ""
    while theme_info.blank? and style_urls.any?
      theme_info = search_for_wp_theme_info style_urls.shift
    end

    # otherwise, find theme by introspecting the url for the CSS files
    theme_info = search_for_wp_theme_by_introspection styles, url if theme_info.blank?

    puts theme_info

    # if we have theme information, output it
    if theme_info
      theme_info
    else
      # raise an error
    end
  end
  # }}}

  # search for wordpress theme - main method {{{
  def search_for_wp_theme_info(css)
    return if css.blank?
    css = sanitize_url css
    doc = Nokogiri::HTML(open(css)).inner_text
    match = /\/\*(.*theme\s*name.*:.*)\*\//im.match(doc)
    return if match.blank?
    prepare_info_output match.to_s
    info = []
    match.to_s.each_line do |line|
      line = line.split(':', 2).map { |x| x.strip }
      info << { :key => line[0], :value => line[1] } unless line[1].blank?
    end
    info << { :key => "CMS", :value => "WordPress" }
  end
  # }}}

  # search for wordpress theme - introspection method {{{
  def search_for_wp_theme_by_introspection(styles, url)
    styles.each do |style|
      css = style.attribute('href').to_s
      match = css.match(/.*\/themes\/(.*)\/.*/i)
      unless match[1].blank?
        return [
          {:key => "Theme Name", :value => match[1].to_s },
          {:key => "Theme URI",  :value => URI.parse(url).host },
          {:key => "CMS", :value => "WordPress" },
          {:key => "method",  :value => "introspection" },
        ]
      end
    end
  end
  # }}}
# }}}

  # get absolute url and sanitize it.
  def sanitize_url(url, relative = "")
    if relative and URI.parse(url).host.nil?
      # get the hostname for the relative url (host which is being queried for)
      host = URI.parse(relative).host
      # prepend url if we have a relative url
      url = /^\//.match(url) ? host + url : relative + url
    end
    # prepend scheme if it is missing one.. use URI class?
    url = /^http/.match(url) ? url : "http://#{url}"

    # return
    url
  end

end
