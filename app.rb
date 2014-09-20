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
    Dir[File.join(File.dirname(__FILE__), "views/sections/") + "*.haml"]
  end

  def nokogiri_doc(file)
    html = Haml::Engine.new(File.read(file)).render
    Nokogiri::HTML(html)
  end

  # FIXME: turn this into recursive function
  # returns toc in format: { h3 => { h4 => [ h5, ... ], ... }, ... }
  def generate_toc
    toc = {}

    section_files.each do |file|

      doc = nokogiri_doc(file)

      h3s = doc.xpath("//*[name()='h3']")

      h3s.each_with_index do |h3, h3i|

        toc[h3] = {}

        if h3s[h3i + 1]

          # text inside the link
          current_h3_text = h3.xpath('.//a')
          next_h3_text    = h3s[h3i + 1].xpath('.//a')

          # get h4s in between current and next h3s
          ap doc.xpath("//h4[preceding-sibling::h3[child::a[. = '#{clean_title current_h3_text}']]
                        and following-sibling::h3[child::a[. ='#{clean_title next_h3_text}']]]")
        else
          # last h3, get the rest of the h4s..
          h4s = doc.xpath("//h4[preceding-sibling::h3[child::a[. = '#{clean_title h3.text}']]]")

          h4s.each do |h4|
            toc[h3][h4] = {}
          end
        end
      end
    end

    puts "toc:"
    ap toc

    #  doc.xpath('//h3/following-siblings')


    #  #doc.css('h3').each do |h3|
    #  #  toc[clean_title(h3.content)] = {}

    #  #  #doc.css('h4').each do |h4|
    #  #  #  toc[h3.content][h4.content] = {}

    #  #  #  doc.css('h5').each do |h5|
    #  #  #    toc[h3.content][h4.content] = [] unless toc[h3][h4]

    #  #  #    toc[h3.content][h4.content].push h5.content
    #  #  #  end
    #  #  #end
    #  #end

    #ap toc

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
