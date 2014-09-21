#!/usr/bin/env ruby

require 'sinatra'
require 'nokogiri'
require 'redcarpet'

require 'haml'
require 'sass'

require 'ap'
require 'pp'
require 'yaml'

# this auto-reloads files with changed mtime
Sinatra::Application.reset!

set :haml, { :ugly=>true }

helpers do
  def clean_title(string)
    string.gsub(/^\n */, '').chomp
  end

  def snake_case(string)
    string.downcase.gsub(' ', '_')
  end

  def section_files
    Dir[File.join(File.dirname(__FILE__), "views/sections/") + "audio.haml"]
  end

  def nokogiri_doc(file)
    html = Haml::Engine.new(File.read(file)).render
    Nokogiri::HTML(html)
  end

  # returns toc in format: { h3 => { h4 => [ h5, ... ], ... }, ... }
  def generate_toc
    file = File.join(File.dirname(__FILE__), "views/sections/") + "audio.haml"

    doc = nokogiri_doc(file)

    toc = get_headers(doc, 'h3')
    ap toc
    toc
  end

  def get_headers(doc, top_header)
    headers = doc.xpath("//*[name()='#{top_header}']")
    toc = {}

    headers.each_with_index do |header, header_index|

      toc[header] = {}

      # this sucks 
      next_header = "h#{header.name[1].to_i + 1}"

      if headers[header_index + 1]

        current_header_text = clean_title header.text
        next_header_text    = clean_title headers[header_index + 1].text

        # get headers in between current and next header
        sub_headers = doc.xpath("
          //#{next_header}
          [preceding-sibling::#{header.name}[child::a[. = '#{current_header_text}']]
            and following-sibling::#{header.name}[child::a[. ='#{next_header_text}']]]
        ")
      else
        # last header, get the rest of the sub headers..
        sub_headers = doc.xpath("
          //#{next_header}
          [preceding-sibling::#{header.name}
            [child::a[. = '#{clean_title header.text}']]]
        ")
      end

      sub_headers.each do |sub_header|
        toc[header][sub_header] = get_headers(doc, sub_header.name)
      end
    end

    toc
  end
end

get '/css/:style.css' do
  scss :"#{params[:style]}"
end

get '/' do
  # FIXME: only do on contents change..
  @toc = generate_toc

  haml :index
end
