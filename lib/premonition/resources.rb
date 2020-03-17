# frozen_string_literal: true

module Jekyll
  module Premonition
    class Resources
      attr_reader :config
      attr_reader :markdown

      def initialize(site_config)
        @config = load site_config
        @markdown = Converters::Markdown.new site_config
      end

      def load(site_config)
        cfg = default_config
        p = site_config['premonition'] || {}
        df = p['default'] || {}
        validate_defaults df, p
        cfg['default']['template'] = df['template'].strip unless df['template'].nil?
        cfg['default']['title'] = df['title'].strip unless df['title'].nil?
        cfg['default']['meta'] = cfg['default']['meta'].merge(df['meta']) unless df['meta'].nil?
        load_types p, cfg
        load_extensions p, cfg
        cfg
      end

      def default_config
        {
          'default' => {
            'template' => '<div class="premonition {{type}}"><i class="{% if meta.fa-icon %}fas {{meta.fa-icon}}{% else %}premonition {{meta.pn-icon}}{% endif %}"></i>'\
              '<div class="content">{% if header %}<p class="header">{{title}}</p>{% endif %}{{content}}</div></div>',
            'meta' => { 'pn-icon' => 'pn-square', 'fa-icon' => nil },
            'title' => nil
          },
          'types' => {
            'note' => { 'meta' => { 'pn-icon' => 'pn-note' } },
            'info' => { 'meta' => { 'pn-icon' => 'pn-info' } },
            'warning' => { 'meta' => { 'pn-icon' => 'pn-warn' } },
            'error' => { 'meta' => { 'pn-icon' => 'pn-error' } },
            'citation' => { 'meta' => { 'pn-icon' => 'pn-quote' }, 'template' =>
              '<div class="premonition {{type}}"><i class="{% if meta.fa-icon %}fas {{meta.fa-icon}}{% else %}premonition {{meta.pn-icon}}{% endif %}"></i>'\
              '<blockquote class="content blockquote"{% if attrs.cite %} cite="{{attrs.cite}}"{% endif %}>{{content}}{% if header %}'\
              '<footer class="blockquote-footer">'\
              '<cite title="{{title}}">{{title}}</cite></footer>{% endif %}</blockquote></div>' }
          },
          'extensions' => [
            'md',
            'markdown'
          ]
        }
      end

      def validate_defaults(df, prem)
        fail 'meta must be a hash' if !df['meta'].nil? && !df['meta'].is_a?(Hash)
        fail 'types must be a hash' if !prem['types'].nil? && !prem['types'].is_a?(Hash)
      end

      def load_types(p, cfg)
        return if p['types'].nil?

        p['types'].each do |id, obj|
          t = type_config id, obj
          cfg['types'][id] = cfg['types'][id].merge(t) unless cfg['types'][id].nil?
          cfg['types'][id] = t if cfg['types'][id].nil?
        end
      end

      def load_extensions(p, cfg)
        return if p['extensions'].nil?
        return unless p['extensions'].is_a?(Array)
        return if p['extensions'].empty?

        cfg['extensions'] = []
        p['extensions'].each do |v|
          cfg['extensions'] << v unless cfg['extensions'].include?(v)
        end
      end

      def type_config(id, t)
        validate_type(id, t)
        {
          'template' => t['template'].nil? ? nil : t['template'].strip,
          'default_title' => t['default_title'].nil? || t['default_title'].empty? ? nil : t['default_title'].strip,
          'meta' => t['meta'].nil? ? {} : t['meta']
        }
      end

      def validate_type(id, t)
        fail 'id missing from type' if id.nil?
        fail "id can only be lowercase letters: #{id}" unless id[/[a-z]+/] == id
        fail 'meta must be an hash' if !t['meta'].nil? && !t['meta'].is_a?(Hash)
      end

      def fail(msg)
        Jekyll.logger.error 'Fatal (Premonition):', msg
        raise LoadError, msg
      end
    end
  end
end
