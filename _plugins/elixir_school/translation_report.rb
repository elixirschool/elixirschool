module ElixirSchool
  class TranslationReport < Jekyll::Generator
    priority :low

    def generate(site)
      locales = site.data['locales'].keys.sort.delete_if { |lang| lang == 'en' }

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

      site.config['tree']['en'].each do |section, section_content|
          section_content.each do |lesson, lesson_content|
            report[section][lesson] = {
              'lesson'             => lesson_content['title'],
              'original_version'   => prettify_version(lesson_content['version']),
              'translated_title'   => translated_value(site, lang, section, lesson, 'title'),
              'translated_version' => prettify_version(translated_value(site, lang, section, lesson, 'version')),
              'version_severity'   => translated_value(site, lang, section, lesson, 'version_severity')
            }
        end
      end

      {
        'headers'  => site.data['locales'][lang]['translation_report'] || site.data['locales']['en']['translation_report'],
        'sections' => report
      }
    end

    def prettify_version(version)
      version.is_a?(Array) ? version.join('.') : ''
    end

    def translated_value(site, lang, section, lesson, key)
      site.config['tree'][lang][section][lesson][key]
    rescue
      if key == 'version_severity'
        'missing'
      end
    end
  end
end
