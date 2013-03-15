america = Country.find_by_code('US')
access = Category.find_by_name('access')
activity = Category.find_by_name('activity')

country.score
country.score :for => access
country.score :for => activity

access.indicators.for(america).each do |i|
        "#{i.name} - Min: #{i.min}; Percentile: #{(i.max-i.min) / (i.value - i.min)}; Max: #{i.max}"
    end
end

access.url_lists.for(america).each do |list|
    "#{list.name}"
    list.urls.each do |url|
        "#{url}"
    end
end

activity.images.for(america).each do |image|
    "#{image.source.name}"
    %Q|<img src="#{image.src}" alt="#{image.alt}" />|
end

access.html_blocks.for(america).each do |html|
    render raw html
end

class Country
    has_many :country_categories
    has_many :country_languages
    has_many :categories, :through => :country_categories
    has_many :languages, :through => :country_languages

    def score(options = {})
        return read_attribute(:score) unless options
        options.assert_valid_keys(:for)
        options.delete_if { |key, value| value.nil? }
        country_categories.where(:category_id => { options[:for].id }).first.score
    end

    def recalc_scores!
    end
end

class CountryCategory
    attr_reader :score
    belongs_to :country
    belongs_to :category
end

class Datum
    attr_reader :type
    serialize :value
    belongs_to :source, :class_name => 'DatumSource'
    belongs_to :country
    default_scope order('start_date DESC').first
    scope :for, lambda { |country| where(:country => country) }
    delegate :name, :description, :to => :source
end

class UrlList < Datum
    alias_attribute :urls, :value
end

class Indicator < Datum
    delegate :min, :max, :to => :source
end

class Image < Datum
    def src
        value[:src]
    end

    def alt
        value[:alt]
    end
end

class HtmlBlock < Datum
    alias_attribute :html, :value
    def to_s
        html
    end
end

class Category
    attr_reader :name
    has_many :datum_sources
    has_many :url_lists, :through => :datum_sources
    has_many :indicators, :through => :datum_sources
    has_many :images, :through => :datum_sources
    has_many :html_blocks, :through => :datum_sources
    #has_many :people, :through => :widget_groupings, :conditions => { :type => 'Person' }, :source => :grouper, :source_type => 'SentientBeing'
    #has_many :aliens, :through => :widget_groupings, :conditions => { :type => 'Alien' }, :source => :grouper, :source_type => 'SentientBeing'
end

class DatumSource
    attr_reader :name, :type, :description, :min, :max, :default_weight, :is_api, :retreiver_class
    belongs_to :category
    has_many :data
    has_one :ingester
    delegate :ingest_data!, :to => :ingester

    def recalc_min_max!
    end

    def ingest_data!(filename = nil)
        if is_api
            data = @retreiver_class.data
        else
            data = @retreiver_class.data(filename)
        end
        data.each do |datum|
            datum.type = datum_source.type
            datum.save
        end
    end
end

class AkamaiParser < XlsxParser
    require 'roo'
    #all floats
    #remove US states rows
    #map country name to country code
    #convert "Q\d \d\d\d\d" to latest date
    #get indicator name from sheet name
    def data(filename)
        data = []
        data << Datum.new(:start_date => start_date, :country => country, :language => language, :datum => datum)
    end
end

class MorningsideFetcher
    def data
        data << Datum.new(:start_date => start_date, :country => country, :language => language, :datum => {:src => src, :alt => alt})
    end
end

class HerdictFetcher
    def data
        data = []
        urls = []
        data << Datum.new(:start_date => start_date, :country => country, :language => language, :datum => urls)
    end
end

class XlsxParser
end

#local data file types:
#xlsx
#csv
#xls
#xml

#remote data file types:
#api

# When does data actually get imported?
# On a schedule?
# Are we talking about an API or file?
# When it's a file, data gets updated when it gets added
# When it's an API, update on an schedule in the background
#
# Things in refinery: everything
# Things for CMS: Countries, datum sources, languages, categories
#
# use roo
