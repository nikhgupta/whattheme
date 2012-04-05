require 'nokogiri'
require 'open-uri'
require 'uri'
class ThemesController < ApplicationController

  respond_to :json

  def discover
    url = sanitize_url params[:url]
    myuseragent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/535.19 (KHTML, like Gecko) Chrome/18.0.1025.142 Safari/535.19"
    doc = Nokogiri::HTML(open(url, 'User-Agent' => myuseragent))
    styles = doc.css('link[type="text/css"]')

    style_urls = styles.collect { |style| sanitize_url style.attribute('href'), url }

    theme_info = ""
    while theme_info.blank?
      theme_info = search_for_wp_theme_info style_urls.shift
    end

    if theme_info
      respond_with prepare_info_output(theme_info)
    else
      theme_name = find_theme_by_introspection style_urls
      #prepare_and_send_info theme_info
    end
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

  def search_for_wp_theme_info(css)
    return if css.nil?
    doc = Nokogiri::HTML(open(css))
    /\/\*(.*theme.*name.*:.*)\*\//im.match(doc).to_s
  end

  def prepare_info_output(info)
    newinfo = []
    info.each_line do |line|
      line = line.split(':', 2).map { |x| x.strip }
      newinfo << { :key => line[0], :value => line[1] } unless line[1].blank?
    end
    newinfo
  end

  def find_theme_by_introspection(style_urls)
    style_urls.each do |css|
      match = /.*\/themes\/(.*)\/.*/i.match(css)
      puts css, match
      return match.to_s if match
    end
  end
end
