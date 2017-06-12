module Languages
  class Generator < Jekyll::Generator
    def generate(site)
      languages = languages(site)
      # Assign global variables
      site.config['languages'] = languages

      # Build chapter tree of the whole site
      # Assign global variable site.tree
      build_tree(site)

      # Build menu and interlang names
      # Assign global variable site.menu and site.interlang_names
      site.config['menu'] = {}
      site.config['interlang_names'] = {}
      languages.each do |lang|
        site.config['menu'][lang] = menu(site, lang)
        site.config['interlang_names'][lang] = interlang_names(site, lang, " / ")
      end
    end

    private
    def build_tree(site)
      site.config['tree'] = {}

      site.pages.each do |page|
        lang    = get_lang_from_url(site, page.url)
        section = get_section_from_url(site, page.url)
        chapter_name = get_chapter_from_url(site, page.url)

        # set page variables
        page.data['lang'] = lang
        page.data['section'] = section
        page.data['chapter'] = chapter_name
        page.data['locale'] = site.data['locales'][lang]

        if section and chapter_name
          site.config['tree'][lang] ||= {}
          site.config['tree'][lang][section] ||= {}
          site.config['tree'][lang][section][chapter_name] =
            { 'url'     => page.url,
              'title'   => page['title'],
              'version' => page['version'],
              'lang'    => lang,
              'section' => section,
              'chapter' => chapter_name,
              'interlang' => {},
             }
        end
      end

      site.config['tree'].each do |lang, sections|
        sections.each do |section, chapters|
          chapters.each do |chapter_name, chapter|
            site.config['tree'][lang][section][chapter_name]['interlang'] =
              interlang(site, section, chapter_name)
          end
        end
      end
      site
    end

    def get_lang_from_url(site, url)
      url_split = url.split('/')

      if url_split.size >= 2
        url_split[1]
      else
        site.config['default_lang']
      end
    end

    def get_section_from_url(site, url)
      url_split = url.split('/')

      if url_split[2] == "lessons" and url_split[3] != nil
        url_split[3]
      elsif url_split.size == 2
        "home"
      else
        nil
      end
    end

    def get_chapter_from_url(site, url)
      url_split = url.split('/')

      if url_split[2] == "lessons" and url_split[4] != nil
        url_split[4]
      elsif url_split.size == 2
        "home"
      else
        nil
      end
    end

    # builds the menu based on the order given in `chapters` datafile
    def menu(site, lang)
      menu = Hash.new
      site.data['chapters'].each do |section, chapters|
        chapters.each_with_index do |chapter_name, index|
          if chapter = get_chapter(site, lang, section, chapter_name)
            chapter['chapter_number'] = index + 1
            menu ||= {}
            menu[section] ||= {}
            menu[section][chapter_name] = chapter
          end
        end
      end
      menu
    end

    def get_chapter(site, lang, section, chapter_name)
      site.config.dig('tree', lang, section, chapter_name)
    end

    def languages(site)
      site.data['locales'].keys.sort
    end

    def interlang(site, section, chapter_name)
      interlang = {}

      languages(site).each do |lang|
        if chapter = site.config['tree'].dig(lang, section, chapter_name)
          interlang[lang] = {'title' => chapter['title'], 'url' => chapter['url']}
        end
      end
      interlang
    end

    def interlang_names(site, original_lang, separator)
      names = {}
      languages(site).each do |lang|
        original_lang_name = site.data['interlang'].dig(original_lang, lang)
        foreign_lang_name = site.data['interlang'].dig(lang, lang)

        if original_lang_name and foreign_lang_name and original_lang_name != foreign_lang_name
          combined_lang_name = "#{original_lang_name}#{separator}#{foreign_lang_name}"
        elsif original_lang_name
          combined_lang_name = "#{original_lang_name}"
        elsif foreign_lang_name
          combined_lang_name = "#{foreign_lang_name}"
        else
          combined_lang_name = nil
        end

        if foreign_lang_name or combined_lang_name
          names[lang] = {
            'foreign' => foreign_lang_name,
            'combined' => combined_lang_name,
          }
        end
      end
      names
    end
  end
end