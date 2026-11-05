/// Firestore collection and field constants
class FirestoreConstants {
  FirestoreConstants._();

  // Collection Names
  static const String users = 'users';
  static const String mobileStock = 'mobile_stock';
  static const String gadgetStock = 'gadget_stock';
  static const String transportCosts = 'transport_costs';
  static const String sales = 'sales';
  static const String customers = 'customers';
  static const String payments = 'payments';
  static const String capital = 'capital';
  static const String salary = 'salary';
  static const String expenses = 'expenses';
  static const String employees = 'employees';
  static const String returns = 'returns';
  static const String damageEvents = 'damage_events';

  // Common Fields
  static const String id = 'id';
  static const String userId = 'userId';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';

  // User Fields
  static const String email = 'email';
  static const String pin = 'pin';
  static const String businessName = 'businessName';
  static const String language = 'language';

  // Mobile Stock Fields
  static const String date = 'date';
  static const String modelName = 'modelName';
  static const String imeiNumber = 'imeiNumber';
  static const String purchaseRate = 'purchaseRate';
  static const String transportCost = 'transportCost';
  static const String netPurchasePrice = 'netPurchasePrice';
  static const String sellingPrice = 'sellingPrice';
  static const String profit = 'profit';
  static const String status = 'status';
  static const String soldDate = 'soldDate';
  static const String damageReason = 'damageReason';
  static const String isReturned = 'isReturned';
  static const String returnCount = 'returnCount';
  static const String returnReason = 'returnReason';
  static const String returnedAt = 'returnedAt';

  // Gadget Stock Fields
  static const String productCode = 'productCode';
  static const String productName = 'productName';
  static const String quantity = 'quantity';
  static const String purchasePrice = 'purchasePrice';
  static const String packagingCost = 'packagingCost';
  static const String storageCost = 'storageCost';
  static const String marketingCost = 'marketingCost';
  static const String damageCost = 'damageCost';
  static const String otherCosts = 'otherCosts';
  static const String productCost = 'productCost';
  static const String profitMargin = 'profitMargin';
  static const String stockStatus = 'stockStatus';
  static const String damagedQuantity = 'damagedQuantity';
  static const String damageValue = 'damageValue';

  // Transport Fields
  static const String perKgPrice = 'perKgPrice';
  static const String productWeightGrams = 'productWeightGrams';
  static const String perGramPrice = 'perGramPrice';

  // Sales Fields
  static const String productType = 'productType';
  static const String productId = 'productId';
  static const String totalAmount = 'totalAmount';
  static const String customerId = 'customerId';
  static const String customerName = 'customerName';
  static const String contactNumber = 'contactNumber';
  static const String paymentStatus = 'paymentStatus';
  static const String paidAmount = 'paidAmount';
  static const String dueAmount = 'dueAmount';
  static const String returnedQuantity = 'returnedQuantity';
  static const String returnedAmount = 'returnedAmount';
  static const String returnStatus = 'returnStatus';

  // Customer Fields
  static const String name = 'name';
  static const String totalDue = 'totalDue';
  static const String totalPaid = 'totalPaid';
  static const String remainingDue = 'remainingDue';

  // Payment Fields
  static const String saleId = 'saleId';
  static const String amount = 'amount';
  static const String paymentMethod = 'paymentMethod';
  static const String notes = 'notes';

  // Capital Fields
  static const String initialCapital = 'initialCapital';
  static const String capitalInvested = 'capitalInvested';
  static const String capitalRecovered = 'capitalRecovered';
  static const String availableCapital = 'availableCapital';
  static const String month = 'month';

  // Status Values
  static const String sold = 'sold';
  static const String unsold = 'unsold';
  static const String paid = 'paid';
  static const String partialPaid = 'partial';
  static const String unpaid = 'unpaid';
  static const String inStock = 'in_stock';
  static const String lowStock = 'low_stock';
  static const String outOfStock = 'out_of_stock';

  // Product Types
  static const String mobile = 'mobile';
  static const String gadget = 'gadget';
}
