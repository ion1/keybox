#
#--
#
# news.rb
# Copyright (c) 2006 Jeremy Hinegardner
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program; if not,
# write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#++
#

require 'parsedate'
require 'stringio'

# This plugin creates a 'news' tag which can be used to display the
# contents of a news file.
#
# The news file by default is 'news.yaml' and placed in the root of
# the webgen directory.  This can be changed with the 'filename'
# parameter.
#
# The yaml file has the basic format of
#
#   date: content
#   date: content
#
# Where the date has the format indicated by the 'dateFormat'
# parmater, which by default is YYYY-MM-DD.  The content is formated
# according to the 'contentFormat' parameter and is textile by
# default.  I recommend using the '|' version of block text for the
# content.  For example:
#
#   2007-03-20: |
#       h2. this is an entry
#
#       This is some content
#
# When utilzed in a template the 'news' tag can optionally take to
# additional parameters 'maxEntries' and 'maxParagraphs'.  
#
#   maxEntries: the N most recent entries by date in the news.yaml
#               file to display.
#
#   maxParagraphs: the content of an entry is truncated to N
#                  paragraphs, where a paragraphs ending is defined by
#                  "\n\n"
# 
# So the following usage of the news tag would disply the first
# paragraph of the most recent item in the news.yaml file.
#
#   {news: {options: {maxEntries: 1, maxParagraphs: 1}}}
#
# While this usage would display all the contents of the news.yaml file
# sorted in reverse chronological order and displayed fully.
#
#   {news: }
#
#
class NewsTag < Tags::DefaultTag

    infos( :name => 'Tag/News',
           :author => "Jeremy Hinegardner",
           :summary => "Process a news file and format it on a page."
         )

    param 'filename', "news.yaml", "The name of the news file, relative to website root"
    param 'dateFormat', "%Y-%m-%d", "The format of the date for the entry."
    param 'contentFormat', "textile", "The markup format for the content."
    param 'dateTag', "h2", "The HTML tag to surround the date."
    param 'contentTag', nil, "The HTML tag to surround the content entry."
    param 'options', {}, "Options passed to the plugin which formats the news."
    set_mandatory 'filename', true
    
    register_tag 'news'
    
    def process_tag( tag, chain )
        content = StringIO.new
        begin
            news_file = param( 'filename' )
            filename = File.join( param( 'websiteDir', 'Core/Configuration' ), news_file ) unless filename =~ /^(\/|\w:)/
            data = YAML::load( File.read(filename) )

            start_date_tag = param('dateTag')
            end_date_tag   = start_date_tag.gsub(/ .*/,'') # in case people put attributes on the tag
            start_content_tag = param('contentTag') || ''
            end_content_tag   = start_content_tag.gsub(/ .*/,'') # in case people put attributes on the tag

            format         = param('dateFormat')
            content_handler= @plugin_manager['ContentConverter/Default'].registered_handlers[param('contentFormat')]

            limit_entries(data).each do |datetime,entry|
                content.puts "<#{start_date_tag}>#{datetime.strftime(format)}</#{end_date_tag}>"
                content.print "<#{start_content_tag}>" if start_content_tag.length > 0 
                content.print content_handler.call(entry)
                content.print "</#{end_content_tag}>" if start_content_tag.length > 0 
            end
        rescue => boom
            log(:error) { "Given file <#{filename}> specified in <#{chain.first.node_info[:src]}> does not exist or can't be read" }
        end
        content.string
    end

    #######
    private
    #######

    def limit_entries(data)
        # convert the entries to something sortable by date
        time_content_entries = []
        data.each_pair do |date,content|
            case date
            when String
                p = ParseDate.parsedate(date)
            when Date
                p = [date.year, date.month, date.day]
            when DateTime
                p = [date.year, date.month, date.day, date.hour, date.min, date.sec]
            end
            time_content_entries << [Time.mktime(*p), content]
        end

        # limit the entries if there is an options for it
        limit = param('options')['maxEntries'] || time_content_entries.size
        max_paragraphs = param('options')['maxParagraphs'] || nil

        # we want a descending sort
        time_content_entries.sort! { |a,b| b[0] <=> a[0] }

        if max_paragraphs then
            max_paragraphs = max_paragraphs.to_i
            time_content_entries[0...limit].collect do |e|
                e[1] = e[1].split("\n\n")[0...max_paragraphs].join("\n\n")
                e
            end
        else
            time_content_entries[0...limit]
        end
    end

end
