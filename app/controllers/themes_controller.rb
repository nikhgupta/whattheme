require 'nokogiri'
require 'open-uri'
require 'uri'
require 'cgi'

class ThemesController < ApplicationController

  respond_to :json

  def discover
    begin
      @theme = Theme.find_by_uri(params[:url]) || Theme.new({:uri => params[:url]})
      @theme.save if @theme.id.nil? or (@theme.updated_at < 7.days.ago)
    rescue Exception => e
      #raise e.inspect
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

  #def edit
    #@theme = Theme.find(params[:id])
    #render_json @theme, params
  #end

  #def create
    #@theme = Theme.new(params[:theme])
    #render_json @theme, params
  #end

  #def update
    #@theme = Theme.find(params[:id])
    #@theme.update_attributes(params[:theme])
    #render_json @theme, params
  #end

  #def destroy
    #@theme = Theme.find(params[:id])
    #@theme.destroy
    #render_json @theme, params
  #end



  private
  def render_json(object, params)
    if params[:callback]
      render :json => object, :callback => params[:callback]
    else
      respond_with object
    end
  end

end
