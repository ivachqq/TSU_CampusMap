class Cafe {
  final String name;
  final int gridX;
  final int gridY;
  int? clusterId;
  Cafe(this.name, this.gridX, this.gridY);
}

final List<Cafe> allCafes = [
  Cafe("Старбукс", 185, 129),
  Cafe("Сибирские блины", 185, 119),
  Cafe("Главная столовая", 185, 119),
  Cafe("Кафе во 2 корпусе", 152, 164),
  Cafe("Столовая 2 корпус", 152, 164),
  Cafe("Сырбор", 183, 45),
  Cafe("Абрикос", 16, 34),
  Cafe("Ярче", 464, 66),
  Cafe("Rostics", 386,225)
];