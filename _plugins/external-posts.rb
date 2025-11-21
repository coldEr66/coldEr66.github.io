# _plugins/external-posts.rb
require "open-uri"
require "feedjira"
require "jekyll"

module ExternalPosts
  class ExternalPostsGenerator < Jekyll::Generator
    safe true
    priority :high

    def generate(site)
      (site.config["external_sources"] || []).each do |src|
        Jekyll.logger.info "ExternalPosts:", "Fetching #{src["name"]} (#{src["rss_url"]})"
        feed = fetch_feed(src["rss_url"])
        next unless feed

        feed.entries.each do |e|
          # ... your existing code that converts entries to Jekyll posts ...
        end
      end
    end

    private

    def fetch_feed(url)
      io = URI.open(
        url,
        "User-Agent" => "Mozilla/5.0 (compatible; FeedFetcher; +https://github.com/feedjira/feedjira)",
        "Accept" => "application/atom+xml, application/rss+xml, text/xml;q=0.9, */*;q=0.8",
        read_timeout: 15,
        open_timeout: 10
      )

      body = io.read
      if body.nil? || body.strip.empty? || !(io.content_type&.include?("xml") || body.lstrip.start_with?("<"))
        Jekyll.logger.warn "ExternalPosts:", "Non-XML or empty response from #{url} (#{io.content_type || 'unknown'}). Skipping."
        return nil
      end

      Feedjira.parse(body)
    rescue Feedjira::NoParserAvailable => e
      Jekyll.logger.warn "ExternalPosts:", "Cannot parse response from #{url}: #{e.message}. Skipping."
      nil
    rescue OpenURI::HTTPError, IOError, Timeout::Error => e
      Jekyll.logger.warn "ExternalPosts:", "HTTP error for #{url}: #{e.class} #{e.message}. Skipping."
      nil
    end
  end
end
