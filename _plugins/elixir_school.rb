module ElixirSchool
  class Generator < Jekyll::Generator

    def generate(site)
      default_lang = site.config['default_lang']
      languages = languages(site)

      # Assign global variables
      site.config['languages'] = languages
      site.config['default_locale'] = site.data['locales'][default_lang]

      # Build chapter tree of the whole site
      # Assign global variable site.tree
      build_tree(site)

      # Build menu and interlang names
      # Assign global variable site.menu and site.interlang_names
      site.config['contents'] = {}
      site.config['interlang_names'] = {}
      languages.each do |lang|
        site.config['contents'][lang] = contents(site, lang)
        site.config['interlang_names'][lang] = interlang_names(site, lang, " / ")
      end
    end

    private
    def build_tree(site)
      site.config['tree'] = {}
      default_lang = site.config['default_lang']

      site.pages.each do |page|
        next if site.config['exclude_from_chapters'].include? page.name
        lang    = get_lang_from_url(site, page.url)
        section = get_section_from_url(site, page.url)
        chapter_name = get_chapter_from_url(site, page.url)

        # set page variables
        page.data['lang'] = lang
        page.data['section'] = section
        page.data['chapter'] = chapter_name
        page.data['locale'] = site.data['locales'][lang]

        # Chapter data
        if section and chapter_name
          site.config['tree'][lang] ||= {}
          site.config['tree'][lang][section] ||= {}
          site.config['tree'][lang][section][chapter_name] =
            { 'url'     => page.url,
              'title'   => page['title'],
              'version' =>
                if page['version']
                  page['version'].split(".").map(&:to_i)
                else
                  nil
                end,
              'version_severity' => nil,
              'lang'    => lang,
              'section' => section,
              'chapter' => chapter_name,
              'interlang' => {},
             }
        end
      end

      # Add additional data once the tree has been built
      site.config['tree'].each do |lang, sections|
        sections.each do |section, chapters|
          chapters.each do |chapter_name, chapter|
            # Interlang data
            site.config['tree'][lang][section][chapter_name]['interlang'] =
              interlang(site, section, chapter_name)

            # Version severity
            if default_lang == lang
              version_severity = "none"
            else
              reference_version = site.config['tree'][default_lang][section][chapter_name]['version']
              version_severity = version_severity(reference_version, chapter['version'])
            end
            site.config['tree'][lang][section][chapter_name]['version_severity'] = version_severity
          end
        end
      end

      # last pass to define page.data['leaf']
      site.pages.each do |page|
        next if site.config['exclude_from_chapters'].include? page.name
        lang = page.data['lang']
        section = page.data['section']
        chapter_name = page.data['chapter']
        leaf = site.config['tree'][lang][section][chapter_name]

        page.data['leaf'] = leaf
        page.data['version_severity'] = leaf['version_severity']
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

    # builds the contents based on the order given in `contents` datafile
    def contents(site, lang)
      previous = nil

      contents = {}
      site.data['contents'].each do |section, chapters|
        chapters.each_with_index do |chapter_name, index|
          if chapter = get_chapter(site, lang, section, chapter_name)
            chapter['chapter_number'] = index + 1
            current = {
              'section' => section,
              'chapter' => chapter_name
            }

            contents[section] ||= {}
            contents[section][chapter_name] = chapter
            # insert 'previous' in current chapter
            contents[section][chapter_name]['previous'] = previous
            # insert 'next' in previous chapter
            if previous != nil
              contents[previous['section']][previous['chapter']]['next'] = current
            end

            # update previous for next iteration
            previous = current
          end
        end
      end
      # set 'next' for last contents entry
      contents[previous['section']][previous['chapter']]['next'] = nil

      contents
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

    def version_severity(reference_version, version)
      if reference_version.is_a?(Array) and version.is_a?(Array)
        if reference_version[0] > version[0]
          "major"
        elsif reference_version[1] > version[1]
          "minor"
        elsif reference_version[2] > version[2]
          "patch"
        elsif reference_version == version or reference_version[2] < version[2]
          "none"
        else
          "error"
        end
      else
        "error"
      end
    end
  end
end
