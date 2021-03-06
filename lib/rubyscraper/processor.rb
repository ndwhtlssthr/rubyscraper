require 'json'
require 'rubyscraper/paginator'
require 'rubyscraper/summary_scraper'
require 'rubyscraper/sub_page_scraper'

class Processor
  attr_reader :sites, :record_limit, :single_site, :scrape_delay

  def initialize(config_file, single_site, record_limit, scrape_delay)
    @scrape_file   = config_file
    @scrape_config = JSON.parse(File.read(@scrape_file))
    @sites         = @scrape_config
    @single_site   = single_site
    @record_limit  = record_limit
    @scrape_delay  = scrape_delay
  end

  def call
    !single_site.empty? ? scrape_single_site : scrape_all_sites
  end

  private

  def scrape_single_site
    site = sites.select { |s| s["name"] == single_site }.first
    scrape_site(site)
  end

  def scrape_all_sites
    sites.inject [] do |all_results, site|
      all_results += scrape_site(site)
    end
  end

  def scrape_site(site)
    paginator = Paginator.new(site, record_limit)
    paginator.define_pagination_params

    results = SummaryScraper.new(site, paginator.add_on, paginator.steps).call
    results = SubPageScraper.new(site, results, scrape_delay).call if has_sub_pages?(site)
    results
  end

  def has_sub_pages?(site)
    site["summary"]["has_sub_pages"] == "true"
  end
end
