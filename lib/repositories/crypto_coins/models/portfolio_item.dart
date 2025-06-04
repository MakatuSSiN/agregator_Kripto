class PortfolioItem {
  final String coinSymbol;
  final String coinName;
  final double amount;
  final String imageUrl;

  PortfolioItem({
    required this.coinSymbol,
    required this.coinName,
    required this.amount,
    required this.imageUrl,
  });

  factory PortfolioItem.fromFirestore(Map<String, dynamic> data, String id) {
    return PortfolioItem(
      coinSymbol: id,
      coinName: data['coinName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}