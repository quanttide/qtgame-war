enum TerrainType {
  plain,
  village,
  town,
  river,
  coreFort,
}

class TerrainProps {
  final String name;
  final int moveCost;
  final int defenseBonus;
  final int color;
  final int fillColor;
  final String icon;
  final bool fullCover;
  final bool isCore;

  const TerrainProps({
    required this.name,
    required this.moveCost,
    required this.defenseBonus,
    required this.color,
    required this.fillColor,
    required this.icon,
    this.fullCover = false,
    this.isCore = false,
  });
}

final Map<TerrainType, TerrainProps> terrainProps = {
  TerrainType.plain: TerrainProps(
    name: '平原',
    moveCost: 1,
    defenseBonus: 0,
    color: 0xffb8a068,
    fillColor: 0xffa89458,
    icon: '',
  ),
  TerrainType.village: TerrainProps(
    name: '村庄',
    moveCost: 1,
    defenseBonus: 1,
    color: 0xff7a8a6a,
    fillColor: 0xff6a7a5a,
    icon: '\u25a3',
  ),
  TerrainType.town: TerrainProps(
    name: '城镇据点',
    moveCost: 2,
    defenseBonus: 2,
    color: 0xff5a4a3a,
    fillColor: 0xff4a3a2a,
    icon: '\u25a3',
  ),
  TerrainType.river: TerrainProps(
    name: '惠济河',
    moveCost: 4,
    defenseBonus: 0,
    color: 0xff3a5a7a,
    fillColor: 0xff2a4a6a,
    icon: '\u2248',
  ),
  TerrainType.coreFort: TerrainProps(
    name: '帝丘店核心',
    moveCost: 3,
    defenseBonus: 4,
    color: 0xff3a1a1a,
    fillColor: 0xff2a0a0a,
    icon: '\u{1F3F0}',
    fullCover: true,
    isCore: true,
  ),
};
