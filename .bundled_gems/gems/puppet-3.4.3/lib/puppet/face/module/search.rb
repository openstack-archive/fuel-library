require 'puppet/util/terminal'
require 'puppet/forge'

Puppet::Face.define(:module, '1.0.0') do
  action(:search) do
    summary "Search the Puppet Forge for a module."
    description <<-EOT
      Searches a repository for modules whose names, descriptions, or keywords
      match the provided search term.
    EOT

    returns "Array of module metadata hashes"

    examples <<-EOT
      Search the Puppet Forge for a module:

      $ puppet module search puppetlabs
      NAME          DESCRIPTION                          AUTHOR             KEYWORDS
      bacula        This is a generic Apache module      @puppetlabs        backups
    EOT

    arguments "<search_term>"

    when_invoked do |term, options|
      Puppet::ModuleTool.set_option_defaults options
      Puppet::ModuleTool::Applications::Searcher.new(term, Puppet::Forge.new("PMT", self.version), options).run
    end

    when_rendering :console do |results, term, options|
      if results[:result] == :failure
        raise results[:error][:multiline]
      end

      return "No results found for '#{term}'." if results[:answers].empty?

      padding = '  '
      headers = {
        'full_name' => 'NAME',
        'desc'      => 'DESCRIPTION',
        'author'    => 'AUTHOR',
        'tag_list'  => 'KEYWORDS',
      }

      min_widths = Hash[ *headers.map { |k,v| [k, v.length] }.flatten ]
      min_widths['full_name'] = min_widths['author'] = 12

      min_width = min_widths.inject(0) { |sum,pair| sum += pair.last } + (padding.length * (headers.length - 1))

      terminal_width = [Puppet::Util::Terminal.width, min_width].max

      columns = results[:answers].inject(min_widths) do |hash, result|
        {
          'full_name' => [ hash['full_name'], result['full_name'].length          ].max,
          'desc'      => [ hash['desc'],      result['desc'].length               ].max,
          'author'    => [ hash['author'],    "@#{result['author']}".length       ].max,
          'tag_list'  => [ hash['tag_list'],  result['tag_list'].join(' ').length ].max,
        }
      end

      flex_width = terminal_width - columns['full_name'] - columns['author'] - (padding.length * (headers.length - 1))
      tag_lists = results[:answers].map { |r| r['tag_list'] }

      while (columns['tag_list'] > flex_width / 3)
        longest_tag_list = tag_lists.sort_by { |tl| tl.join(' ').length }.last
        break if [ [], [term] ].include? longest_tag_list
        longest_tag_list.delete(longest_tag_list.sort_by { |t| t == term ? -1 : t.length }.last)
        columns['tag_list'] =  tag_lists.map { |tl| tl.join(' ').length }.max
      end

      columns['tag_list'] = [
        flex_width / 3,
        tag_lists.map { |tl| tl.join(' ').length }.max,
      ].max
      columns['desc'] = flex_width - columns['tag_list']

      format = %w{full_name desc author tag_list}.map do |k|
        "%-#{ [ columns[k], min_widths[k] ].max }s"
      end.join(padding) + "\n"

      highlight = proc do |s|
        s = s.gsub(term, colorize(:green, term))
        s = s.gsub(term.gsub('/', '-'), colorize(:green, term.gsub('/', '-'))) if term =~ /\//
        s
      end

      format % [ headers['full_name'], headers['desc'], headers['author'], headers['tag_list'] ] +
      results[:answers].map do |match|
        name, desc, author, keywords = %w{full_name desc author tag_list}.map { |k| match[k] }
        desc = desc[0...(columns['desc'] - 3)] + '...' if desc.length > columns['desc']
        highlight[format % [ name.sub('/', '-'), desc, "@#{author}", [keywords].flatten.join(' ') ]]
      end.join
    end
  end
end
