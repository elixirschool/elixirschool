# Aggregate the En lesson versions together
Jekyll::Hooks.register :site, :post_read do |site|
  versions = site.pages.reduce(Hash.new { |h, k| h[k] = [] }, &method(:page_versions))
  site.config["versions"] = versions
end

# Compare a page's version to the master version and populate a warning if necessary
Jekyll::Hooks.register :pages, :pre_render do |page, payload|
  data           = page.data
  category       = data["category"]
  default_lang   = page.site.config["default_lang"]
  lang           = data["lang"]
  order          = data["order"].to_i
  master_version = page.site.config["versions"][category][order]
  page_version   = data["version"] || "0.0.0"

  if master_version
    severity = compare_versions(master_version, page_version)
    unless severity == "same"
      warnings      = page.site.config["warnings"]
      lang_warnings = warnings[lang] || warnings[default_lang]
      msg           = lang_warnings[severity]

      payload["page"]["old_version_warning"] = msg
    end
  end
end

def compare_versions(site, page)
  version = page.split(".").map(&:to_i)
  if site[0] > version[0]
    "major"
  elsif site[1] > version[1]
    "minor"
  elsif site[2] > version[2]
    "patch"
  else
    "same"
  end
end

def page_versions(acc, page)
  data = page.data
  if data["lang"] == "en" && (category = data["category"])
    order   = data["order"].to_i
    version = (data["version"] || "1.0.0").split(".").map(&:to_i)

    # There will be a `nil` at index 0 since no lesson has that order
    acc[category][order] = version
  end
  acc
end
