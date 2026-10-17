import '../models/recycle_category.dart';

/// 분류별 분리배출 안내. 환경부 「재활용품 분리배출 가이드라인」을 바탕으로 정리.
class GuideEntry {
  const GuideEntry({
    required this.category,
    required this.summary,
    required this.howTo,
    required this.allowed,
    required this.notAllowed,
  });

  final RecycleCategory category;
  final String summary;
  final List<String> howTo;
  final List<String> allowed;
  final List<String> notAllowed;
}

const List<GuideEntry> recyclingGuide = [
  GuideEntry(
    category: RecycleCategory.pet,
    summary: '무색 투명 페트병은 다른 플라스틱과 따로 모읍니다.',
    howTo: [
      '내용물을 비우고 물로 헹굽니다.',
      '라벨을 떼어 비닐로 배출합니다.',
      '발로 밟아 찌그러뜨린 뒤 뚜껑을 닫습니다.',
      '투명 페트병 전용 수거함에 넣습니다.',
    ],
    allowed: ['생수병', '무색 음료 페트병'],
    notAllowed: ['색깔 있는 페트병(플라스틱)', '간장·식용유 페트병(플라스틱)', '일회용 컵'],
  ),
  GuideEntry(
    category: RecycleCategory.plastic,
    summary: '깨끗이 비우고 헹군 플라스틱 용기만 재활용됩니다.',
    howTo: [
      '내용물을 비우고 물로 헹굽니다.',
      '라벨, 뚜껑 등 다른 재질은 분리합니다.',
      '플라스틱 수거함에 넣습니다.',
    ],
    allowed: ['샴푸·세제 용기', '요구르트병', '색깔 있는 페트병', '배달 용기(씻은 것)'],
    notAllowed: ['칫솔·볼펜 등 복합재질(일반)', '장난감(일반 또는 대형)', '오염이 심한 용기(일반)'],
  ),
  GuideEntry(
    category: RecycleCategory.paper,
    summary: '물기 없는 종이류는 펴서 묶어 배출합니다.',
    howTo: [
      '테이프, 스프링, 비닐 코팅을 제거합니다.',
      '상자는 펼쳐서 납작하게 만듭니다.',
      '종이류끼리 끈으로 묶어 배출합니다.',
    ],
    allowed: ['신문', '책', '택배 상자', '노트', '종이 쇼핑백'],
    notAllowed: ['영수증(감열지, 일반)', '코팅 종이·사진(일반)', '기름 묻은 피자 상자(일반)', '컵라면 용기(일반)'],
  ),
  GuideEntry(
    category: RecycleCategory.paperPack,
    summary: '우유팩·주스팩은 종이와 섞지 말고 따로 모읍니다.',
    howTo: [
      '내용물을 비우고 물로 헹굽니다.',
      '펼쳐서 말립니다.',
      '종이팩 전용 수거함이 있으면 그곳에, 없으면 종이류와 별도로 묶어 배출합니다.',
    ],
    allowed: ['우유팩', '주스팩', '두유팩(멸균팩은 별도 표시 확인)'],
    notAllowed: ['종이컵(종이팩 또는 지자체 기준 확인)', '플라스틱 뚜껑(플라스틱)'],
  ),
  GuideEntry(
    category: RecycleCategory.can,
    summary: '캔과 고철은 내용물을 비우고 배출합니다.',
    howTo: [
      '내용물을 비우고 헹굽니다.',
      '부탄가스·스프레이는 통풍이 잘 되는 곳에서 가스를 완전히 뺍니다.',
      '캔·고철 수거함에 넣습니다.',
    ],
    allowed: ['음료 캔', '통조림 캔', '부탄가스(가스 제거 후)', '냄비, 프라이팬(손잡이 제거)'],
    notAllowed: ['페인트통 등 내용물 남은 통(유해)', '이물질 묻은 캔(일반)'],
  ),
  GuideEntry(
    category: RecycleCategory.glass,
    summary: '유리병은 뚜껑을 분리하고 깨지지 않게 배출합니다.',
    howTo: [
      '내용물을 비우고 헹굽니다.',
      '뚜껑과 라벨을 분리합니다.',
      '유리병 수거함에 넣습니다. 소주·맥주병은 마트에서 보증금 환급이 됩니다.',
    ],
    allowed: ['소주·맥주병', '음료병', '잼병'],
    notAllowed: ['깨진 유리(신문지에 싸서 일반 또는 불연성 마대)', '내열유리·도자기·거울(불연성 마대)', '유리 식기(불연성 마대)'],
  ),
  GuideEntry(
    category: RecycleCategory.vinyl,
    summary: '깨끗한 비닐만 비닐 수거함으로 갑니다.',
    howTo: [
      '이물질을 털어내고 물기를 제거합니다.',
      '비닐끼리 모아서 배출합니다.',
    ],
    allowed: ['비닐봉지', '과자 봉지', '뽁뽁이', '라면 봉지', '페트병 라벨'],
    notAllowed: ['음식물 묻은 비닐(일반)', '랩(일반 또는 지자체 기준 확인)', '은박 비닐(일반)'],
  ),
  GuideEntry(
    category: RecycleCategory.styrofoam,
    summary: '흰색 깨끗한 스티로폼만 재활용됩니다.',
    howTo: [
      '송장, 테이프를 모두 제거합니다.',
      '이물질을 닦아 냅니다.',
      '부피가 크면 잘게 부수지 말고 그대로 배출합니다.',
    ],
    allowed: ['택배 완충재', '농수산물 상자'],
    notAllowed: ['색깔 있는 스티로폼(일반)', '음식 묻은 컵라면 용기(일반)', '건축용 단열재(대형)'],
  ),
  GuideEntry(
    category: RecycleCategory.food,
    summary: '사람이 먹을 수 있는 부분만 음식물 쓰레기입니다.',
    howTo: [
      '물기를 최대한 제거합니다.',
      '비닐, 이쑤시개 등 이물질을 골라냅니다.',
      '음식물 전용 봉투 또는 수거함에 배출합니다.',
    ],
    allowed: ['남은 밥·반찬', '과일 껍질(얇은 것)', '채소'],
    notAllowed: ['뼈, 조개·게 껍데기(일반)', '복숭아·아보카도 씨(일반)', '달걀 껍질(일반)', '티백·커피 찌꺼기(일반)', '양파·옥수수 껍질(일반)'],
  ),
  GuideEntry(
    category: RecycleCategory.hazardous,
    summary: '건전지, 형광등, 폐의약품은 전용 수거함으로 보냅니다.',
    howTo: [
      '건전지·형광등은 주민센터나 아파트 전용 수거함에 넣습니다.',
      '폐의약품은 약국·보건소·주민센터 수거함에 넣습니다.',
      '절대 일반 쓰레기나 하수구에 버리지 않습니다.',
    ],
    allowed: ['건전지', '보조배터리', '형광등', '먹다 남은 약', '체온계(수은)'],
    notAllowed: ['LED 전구(일반)', '깨지지 않은 백열전구(일반)'],
  ),
  GuideEntry(
    category: RecycleCategory.electronics,
    summary: '폐가전은 크기에 따라 수거 방법이 다릅니다.',
    howTo: [
      '소형 가전은 주민센터·아파트 폐가전 수거함에 넣습니다.',
      '대형 가전(냉장고, 세탁기, TV)은 폐가전 무상방문수거(1599-0903)를 신청합니다.',
      '배터리는 분리해 유해 폐기물로 배출합니다.',
    ],
    allowed: ['휴대폰', '충전기', '드라이기', '전기밥솥', '냉장고·세탁기(무상방문수거)'],
    notAllowed: ['배터리(유해 폐기물)', '전선만 따로(고철 또는 소형가전)'],
  ),
  GuideEntry(
    category: RecycleCategory.clothing,
    summary: '입을 수 있는 옷은 의류 수거함으로 보냅니다.',
    howTo: [
      '세탁한 뒤 건조해서 배출합니다.',
      '동네 의류 수거함에 넣습니다.',
    ],
    allowed: ['옷', '신발', '가방', '커튼', '담요(얇은 것)'],
    notAllowed: ['솜이불·베개(대형 폐기물 또는 종량제)', '젖은 옷(일반)', '속옷·양말(일반)'],
  ),
  GuideEntry(
    category: RecycleCategory.bulky,
    summary: '가구 등 큰 물건은 스티커를 붙여 배출합니다.',
    howTo: [
      '주민센터 방문 또는 지자체 앱·홈페이지에서 대형 폐기물 배출 신고를 합니다.',
      '수수료를 내고 스티커(필증)를 받습니다.',
      '지정된 날짜에 지정 장소에 내놓습니다.',
    ],
    allowed: ['소파', '침대', '책상', '장롱', '자전거'],
    notAllowed: ['대형 가전(폐가전 무상방문수거)'],
  ),
  GuideEntry(
    category: RecycleCategory.general,
    summary: '재활용이 안 되는 것은 종량제 봉투에 버립니다.',
    howTo: [
      '종량제 봉투에 담습니다.',
      '날카로운 것은 종이로 싸서 안전하게 버립니다.',
    ],
    allowed: ['영수증', '기저귀', '물티슈', '복합재질 물건', '오염된 포장재'],
    notAllowed: ['재활용 가능한 깨끗한 용기', '음식물', '건전지·약'],
  ),
];

GuideEntry? guideFor(RecycleCategory category) {
  for (final entry in recyclingGuide) {
    if (entry.category == category) return entry;
  }
  return null;
}
