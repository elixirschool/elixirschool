module ElixirSchool
  class TranslationReport < Jekyll::Generator
    priority :low

    def generate(site)
      locales = site.data['locales'].keys.sort.delete_if { |lang| lang == site.config['default_lang'] }

      locales.each do |lang|
        site.pages << build_report(site, lang, locales)
      end
    end

    private

    def build_report(site, lang, locales)
      page = Jekyll::PageWithoutAFile.new(site, site.source, lang, 'report.md')
      page.data['section'] = 'report'
      page.data['chapter'] = 'report'
      page.data['lang'] = lang
      page.data['translation_report'] = build_translation_report(site, lang)

      build_interlang(site, lang, locales)

      page.content = '{% include report.html %}'

      page
    end

    def build_interlang(site, lang, locales)
      interlang = Hash.new { |h, k| h[k] = {} }

      locales.each do |locale|
        interlang[locale] = {
          'title' => site.data['locales'][locale]['sections']['translation_report'],
          'url' => "/#{locale}/report"
        }
      end

      site.config['tree'][lang]['report'] = {'report' => {'interlang' => interlang}}
    end

    def build_translation_report(site, lang)
      report = Hash.new { |hash, key| hash[key] = Hash.new { |h, k| h[k] = {} }}
      points = 0
      total_lessons = 0

      site.config['tree'][site.config['default_lang']].each do |section, section_content|
          section_content.each do |lesson, lesson_content|
            severity = translated_value(site, lang, section, lesson, 'version_severity')
            translated_severity = site.data['locales'][lang]['version_messages'][severity] || site.data['locales'][site.config['default_lang']]['version_messages'][severity]
            points += translation_points(severity)
            total_lessons += 1

            report[section][lesson] = {
              'lesson'              => lesson_content['title'],
              'chapter'             => lesson_content['chapter'],
              'url'                 => lesson_content['url'],
              'original_version'    => prettify_version(lesson_content['version']),
              'translated_url'      => translated_value(site, lang, section, lesson, 'url'),
              'translated_title'    => translated_value(site, lang, section, lesson, 'title'),
              'translated_version'  => prettify_version(translated_value(site, lang, section, lesson, 'version')),
              'version_severity'    => severity,
              'translated_severity' => translated_severity,
              'last_commit' => severe?(severity) ? find_last_commit(severity, lesson_content) : ''
            }
        end
      end

      {
        'headers'  => site.data['locales'][lang]['translation_report'] || site.data['locales'][site.config['default_lang']]['translation_report'],
        'sections' => report,
        'percentage' => points_to_percentage(points, total_lessons)
      }
    end

    def find_last_commit(severity, lesson_content)
      file = lesson_content["url"].gsub('"', '').gsub(/\/$/, '.md')
      if file == '/en.md'
        file = '/en/index.md'
      end
      git = `git blame -L 2,2 -- #{Dir.pwd}/#{file}`
      "https://github.com/elixirschool/elixirschool/commit/#{git[0..7]}"
    end

    def severe?(severity)
      severity != "none" && severity != "error"
    end

    def prettify_version(version)
      version.is_a?(Array) ? version.join('.') : ''
    end

    def points_to_percentage(points, total_lessons)
      sprintf("%0.2f", (points / total_lessons) * 100)
    end

    def translated_value(site, lang, section, lesson, key)
      site.config['tree'][lang][section][lesson][key]
    rescue
      if key == 'version_severity'
        'missing'
      end
    end

    def translation_points(version_severity)
      case version_severity
      when 'none'
        1.0
      when 'patch'
        0.9
      when 'minor'
        0.7
      when 'major'
        0.5
      else
        0
      end
    end
  end
end
