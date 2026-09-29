# Ignorar las carpetas de Clean Architecture en Zeitwerk para gestionarlas de forma explicita
Rails.autoloaders.main.ignore(
  Rails.root.join("app/core"),
  Rails.root.join("app/infrastructure")
)

# Carga deterministica de las capas de Clean Architecture (POROs desacoplados)
require Rails.root.join("app/core/errors")
Dir[Rails.root.join("app/core/entities/**/*.rb")].sort.each { |f| require f }
Dir[Rails.root.join("app/core/use_cases/**/*.rb")].sort.each { |f| require f }
Dir[Rails.root.join("app/infrastructure/repositories/**/*.rb")].sort.each { |f| require f }
