require "test_helper"

class EntityNavI18nTest < ActiveSupport::TestCase
  ENTITY_NAV_KEYS = %w[
    entity.nav.dereference
    entity.nav.cms_v3
    entity.nav.cms_v4
    entity.nav.minter
    entity.nav.history_logs
    entity.nav.history_log_title
    entity.nav.ranked
    entity.nav.ranked_properties
    entity.nav.aggregator_place_v2
  ].freeze

  test "entity nav labels are translated for english and french" do
    [:en, :fr].each do |locale|
      ENTITY_NAV_KEYS.each do |key|
        translation = I18n.t(key, locale: locale)
        assert translation.present?, "Expected translation for #{key} in #{locale}"
        refute_match(/\Atranslation missing:/, translation, "Missing translation for #{key} in #{locale}")
      end
    end
  end
end
