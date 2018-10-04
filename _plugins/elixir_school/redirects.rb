module ElixirSchool
  class Redirects < Jekyll::Generator
    priority :high

    def generate(site)
      site.data['redirects'].each do |from, to|
        site.data['contents'].each do |category, pages|
          pages.each do |page|
            if (category == 'home')
              page = page == 'home' ? '' : page
              from_page = File.join(from, page)
              to_page = File.join(to, page)
            else
              from_page = File.join(from, 'lessons', category, page)
              to_page = File.join(to, 'lessons', category, page)
            end

            site.pages << JekyllRedirectFrom::RedirectPage.from_paths(site, from_page, to_page)
          end
        end
      end
    end
  end
end
