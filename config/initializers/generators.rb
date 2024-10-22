Rails.application.config.generators do |g|
  g.test_framework :rspec, fixture: false
  g.controller true
  g.helper false
  g.jbuilder false
  g.system_tests false
  g.test_unit false
  g.routing false
end
