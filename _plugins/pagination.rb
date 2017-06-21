# Split the existing pages by language and sort them by `category` and `order`
Jekyll::Hooks.register :site, :post_read do |site|
  categories = site.config["sections"].map { |h| h["tag"] }
  pagination = site.pages.reduce(Hash.new { |h, k| h[k] = [] }, &method(:split_pages_by_lang))
  pagination.each do |lang, pages|
    pages.sort_by! { |h| [ categories.find_index(h["category"]), h["order"].to_i ] }
  end
  site.config["pagination"] = pagination
end

# Append the previous and the next pages' metadata
Jekyll::Hooks.register :pages, :pre_render do |page, payload|
  data = page.data
  lang = data["lang"]
  pagination = page.site.config["pagination"][lang]
  if !data["category"].nil? && !data["order"].nil? && !pagination.nil?
    index = pagination.find_index { |h| h["category"] == data["category"] && h["order"] == data["order"] }
    payload["page"]["pagination"] = {
      "previous" => (pagination[index - 1] if index > 0),
      "next" => (pagination[index + 1] if index < pagination.length - 1)
    }
  end
end

def split_pages_by_lang(acc, page)
  data = page.data
  if !data["category"].nil? && !data["order"].nil?
    if data["lang"] == page.site.config["default_lang"]
      data["path"] = File.join(["", "lessons", data["category"], page.name.chomp(".md"), ""])
    else
      data["path"] = File.join(["", data["lang"], "lessons", data["category"], page.name.chomp(".md"), ""])
    end
    acc[data["lang"]].push(data)
  end
  acc
end