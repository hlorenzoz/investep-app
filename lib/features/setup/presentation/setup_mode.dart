/// Modo del wizard reutilizable [BrokerSetupFlow].
///
/// - [initialSetup]: primera configuración. Incluye el slide de capital inicial.
/// - [addBroker]: agregar una cuenta de broker a un capital ya existente. Omite
///   el slide de capital y deshabilita combinaciones broker+tipo ya configuradas.
enum SetupMode { initialSetup, addBroker }
