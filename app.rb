#!/usr/bin/env ruby

require 'sinatra'
require 'nokogiri'
require 'redcarpet'
require 'ostruct'

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
    file = File.read(File.join(File.dirname(__FILE__), "views/") + "index.haml")

    files = []

    file.each_line do |line|
      if line.match(/.*haml :'sections.*/) and line.match(/.*haml :'sections'.*/).nil?
        files.push File.join(File.dirname(__FILE__), "views/", line.scan(/'(.*)'/)[0][0] + '.haml')
      end
    end

    files
  end

  def nokogiri_doc(file)
    html = Haml::Engine.new(File.read(file)).render
    Nokogiri::HTML(html)
  end

  # returns toc in format: { h3 => { h4 => [ h5, ... ], ... }, ... }
  def generate_toc
    toc = section_files.map do |file|
      doc = nokogiri_doc(file)

      get_headers(doc, 'h3')
    end

    toc
  end

  def get_headers(doc, top_header, title = nil)

    headers = doc.xpath("//*[name()='#{top_header}']")

    toc = []

    headers.each_with_index do |header, header_index|

      h = OpenStruct.new

      h.title = clean_title header.text
      h.link  = header.xpath('.//a')[0]['href'] if header.xpath('.//a')[0]

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

      h.sub_headers = []

      sub_headers.each do |sub_header|
        title = clean_title(sub_header.text)
        h.sub_headers.push get_headers(doc, sub_header.name, title)
      end

      toc.push h
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
