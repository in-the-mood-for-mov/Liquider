class Paginate < Liquid::Block
  include PaginationRestrictions
  include DropPagination

  Syntax     = /(#{Liquid::QuotedFragment})\s*(by\s*(#{Liquid::QuotedFragment}))?/

  DEFAULT_PAGE_SIZE = 20

  # Cap the item offset to avoid MySQL errors due to invalid SQL on huge offset variable leaking to storefront
  MAX_OFFSET = 100000000

  def initialize(tag_name, markup, options)
    super

    if markup =~ Syntax
      @collection_name = $1
      @page_size_reference = $2 ? $3 : DEFAULT_PAGE_SIZE.to_s

      @attributes = { 'window_size' => 3 }
      markup.scan(Liquid::TagAttributes) do |key, value|
        @attributes[key] = value
      end
    else
      raise Liquid::SyntaxError.new("Syntax Error in tag 'paginate' - Valid syntax: paginate [collection] by number")
    end
  end

  def render(context)
    @context = context
    @page_size = restrict_limit(context[@page_size_reference].to_i)
    current_page  = restrict_limit(context['current_page'].to_i)

    context.stack do

      pagination = {
        'page_size'      => @page_size,
        'current_page'   => current_page,
        'current_offset' => (current_page-1) * @page_size
      }
      pagination['current_offset'] = MAX_OFFSET if pagination['current_offset'] > MAX_OFFSET

      context['paginate'] = pagination
      context.registers[:paginated_collection] ||= DropPagination::PaginatedCollection.from_context_and_keypath(context, @collection_name)

      # Get the total item count in the collection
      collection_size = context["#{@collection_name}_count"]
      raise ArgumentError.new("Array '#{@collection_name}' is not paginateable.") if collection_size.nil?

      page_count = (collection_size.to_f / @page_size.to_f).ceil + 1

      pagination['items']      = collection_size
      pagination['pages']      = page_count -1
      pagination['previous']   = link('&laquo; Previous', current_page-1 )  unless 1 >= current_page
      pagination['next']       = link('Next &raquo;', current_page+1 )      unless page_count <= current_page+1
      pagination['parts']      = []

      hellip_break = false

      if page_count > 2
        1.upto(page_count-1) do |page|

          if current_page == page
            pagination['parts'] << no_link(page)
          elsif page == 1
            pagination['parts'] << link(page, page)
          elsif page == page_count -1
            pagination['parts'] << link(page, page)
          elsif page <= current_page - @attributes['window_size'] or page >= current_page + @attributes['window_size']
            next if hellip_break
            pagination['parts'] << no_link('&hellip;')
            hellip_break = true
            next
          else
            pagination['parts'] << link(page, page)
          end

          hellip_break = false
        end
      end

      register_paginated_collection_links(pagination)

      super
    end
  end

  private

  def no_link(title)
    { 'title' => title, 'is_link' => false}
  end

  def link(title, page)
    url = controller.url_for(controller.whitelisted_params.merge(:only_path => true, :page => page))
    { 'title' => title, 'url' => url, 'is_link' => true}
  end

  def controller
    @context.registers[:controller]
  end

  def register_paginated_collection_links(pagination)
    @context.registers[:paginated_collection_links] ||= begin
      links = {}
      links[:prev] = pagination['previous']['url'] if pagination['previous']
      links[:next] = pagination['next']['url']     if pagination['next']
      links
    end
  end
end
