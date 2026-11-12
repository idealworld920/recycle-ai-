# 시군구 분리배출 안내 URL 현황 (2026-11-12)

칸 수는 regions.json 기준(일반구는 시 홈페이지를 공용으로 쓴다). 안내 페이지(이전 확인) 23 · 메인(접속 불가, 미검증) 39 · 메인 폴백(봇 차단) 1 · 안내 페이지 182 · 메인 폴백 11

## 메인으로 폴백한 지역 (안내 페이지를 못 찾음)

- 전남광주통합특별시 담양군 (12710): https://www.damyang.go.kr/index.damyang — home ok; sitemap 환경 section has only 대형폐기물/불법투기/EPR pages; site search '분리배출' re
- 경기도 성남시 수정구 (41131): https://www.seongnam.go.kr/ — main site 환경·위생 section and sitemap have no 쓰레기/분리배출 content page; site search (
- 경기도 성남시 중원구 (41133): https://www.seongnam.go.kr/ — main site 환경·위생 section and sitemap have no 쓰레기/분리배출 content page; site search (
- 경기도 성남시 분당구 (41135): https://www.seongnam.go.kr/ — main site 환경·위생 section and sitemap have no 쓰레기/분리배출 content page; site search (
- 경상북도 상주시 (47250): https://www.sangju.go.kr/main.tc — root is a maintenance/intro page (NetFunnel); main.tc, sitemap, 생활정보 subsite and
- 강원특별자치도 영월군 (51750): https://www.yw.go.kr/www/index.do — no household-waste guide page: sitemap/환경 section only has 대형폐기물처리(key=92), 자원재활
- 강원특별자치도 인제군 (51810): https://www.inje.go.kr/portal — home ok; portal sitemap/분야별정보 has no 청소·환경 waste menu; main page only banners to
- 전북특별자치도 정읍시 (52180): https://www.jeongeup.go.kr/index.jeongeup — 전체메뉴/환경·위생 section and 자원순환과 dept page show no 생활쓰레기 배출 guide (only 관외 전입자 쓰레기 봉
- 전북특별자치도 무주군 (52730): https://www.muju.go.kr/index.9is — homepage intro -> /index.9is; main site 사이트맵/분야별정보 has no 청소·쓰레기·분리배출 menu (only
- 전북특별자치도 임실군 (52750): https://www.imsil.go.kr/index.imsil — main site has no 분리배출 guide menu: 분야별정보 sections are 복지/산업경제/농업귀농/재정/주소/비상대피/장학회
- 전북특별자치도 부안군 (52800): https://www.buan.go.kr/index.buan?contentsSid=1 — home ok; 환경/위생 section has only 음식물쓰레기 page (menuCd=DOM_000000104008009000); sit

## 메인으로 폴백한 지역 (봇 차단으로 안내 페이지 확인 불가)

- 서울특별시 강북구 (11305): https://www.gangbuk.go.kr/

## 접속하지 못해 메인 URL만 넣은 지역 (미검증)

- 서울특별시 용산구 (11170): https://www.yongsan.go.kr/ — www.yongsan.go.kr: 'Empty reply from server' on https root and /portal/main/main
- 전남광주통합특별시 순천시 (12150): https://www.suncheon.go.kr/ — TLS connection reset by peer on every attempt (root, /kr/, http variant); domain
- 전남광주통합특별시 구례군 (12730): https://www.gurye.go.kr/ — proxy gateway 502 on CONNECT to www.gurye.go.kr and gurye.go.kr (retried); gurye
- 전남광주통합특별시 강진군 (12780): https://www.gangjin.go.kr/ — connection reset through proxy on every attempt (www and bare host, 3 rounds); c
- 부산광역시 수영구 (26500): https://www.suyeong.go.kr/ — www.suyeong.go.kr: connection reset / empty reply on https root and /index.suyeo
- 대구광역시 중구 (27110): https://www.jung.daegu.kr/ — www.jung.daegu.kr answers HTTP 400 Bad Request (1.4KB WAF-style page) for / and 
- 인천광역시 계양구 (28245): https://www.gyeyang.go.kr/ — https://www.gyeyang.go.kr/ and /open_content/main/ reset the TLS connection on 3
- 경기도 의정부시 (41150): https://www.ui4u.go.kr/ — curl 60: SSL certificate problem (unable to get local issuer certificate) on www
- 경기도 고양시 덕양구 (41281): https://www.goyang.go.kr/ — https://www.goyang.go.kr/ and /www/index.do reset TLS connection on 3 attempts (
- 경기도 고양시 일산동구 (41285): https://www.goyang.go.kr/ — https://www.goyang.go.kr/ and /www/index.do reset TLS connection on 3 attempts (
- 경기도 고양시 일산서구 (41287): https://www.goyang.go.kr/ — https://www.goyang.go.kr/ and /www/index.do reset TLS connection on 3 attempts (
- 경기도 여주시 (41670): https://www.yeoju.go.kr/ — connection reset through proxy on every attempt (/, /main/yj, bare host; 4 round
- 경상북도 김천시 (47150): https://www.gc.go.kr/ — web firewall blocks the request (404 'contrary to the Web firewall security poli
- 경상북도 영천시 (47230): https://www.yc.go.kr/ — web firewall blocks the request (404 'contrary to the Web firewall security poli
- 경상북도 경산시 (47290): https://www.gbgs.go.kr/open_content/ko/index.do — web application firewall returns 'request contrary to Web firewall security poli
- 경상북도 청송군 (47750): https://www.cs.go.kr/ — www.cs.go.kr web firewall blocks the proxy IP (HTTP 404 'contrary to the Web fir
- 경상북도 영양군 (47760): https://www.yyg.go.kr/ — www.yyg.go.kr returns 404 'request contrary to the Web firewall security policie
- 경상북도 영덕군 (47770): https://www.yd.go.kr/ — WAF block page ('contrary to Web firewall security policies') on root, 2 attempt
- 경상북도 청도군 (47820): https://www.cheongdo.go.kr/ — web firewall blocks the request (404 'contrary to the Web firewall security poli
- 경상북도 고령군 (47830): https://www.goryeong.go.kr/ — www.goryeong.go.kr web firewall blocks the proxy IP (HTTP 404 'contrary to the W
- 경상북도 칠곡군 (47850): https://www.chilgok.go.kr/ — WAF block page ('contrary to Web firewall security policies') on root, 2 attempt
- 경상북도 울릉군 (47940): https://www.ulleung.go.kr/ — WAF block page ('contrary to Web firewall security policies') on root, 2 attempt
- 경상남도 진주시 (48170): https://www.jinju.go.kr/ — www.jinju.go.kr: connection reset by peer on every attempt (8 tries over ~20 min
- 경상남도 거제시 (48310): https://www.geoje.go.kr/ — TLS connection reset by peer on 3 attempts (proxy log: tunnel closed after 15s, 
- 경상남도 의령군 (48720): https://www.uiryeong.go.kr/ — connection reset through proxy on every attempt (www and bare host, 3 rounds)
- 경상남도 함안군 (48730): https://www.haman.go.kr/ — proxy gateway 502 on CONNECT to www.haman.go.kr and haman.go.kr (retried); web s
- 경상남도 창녕군 (48740): https://www.cng.go.kr/ — TLS connection reset by peer on 3 attempts (proxy log: tunnel closed after 15s, 
- 경상남도 고성군 (48820): https://www.goseong.go.kr/ — HTTP 400 Bad Request (166B) on /, /main.do; /index.es resets; domain goseong.go.
- 경상남도 남해군 (48840): https://www.namhae.go.kr/ — connection reset through proxy on every attempt (3 rounds)
- 경상남도 하동군 (48850): https://www.hadong.go.kr/ — www.hadong.go.kr: connection reset by peer on every attempt (8 tries over ~25 mi
- 경상남도 산청군 (48860): https://www.sancheong.go.kr — TLS connection reset by peer on 3 attempts (proxy log: tunnel closed after 15s, 
- 경상남도 함양군 (48870): https://www.hygn.go.kr/ — proxy CONNECT tunnel failed 502 (gateway could not connect) on 3 attempts; domai
- 경상남도 거창군 (48880): https://www.geochang.go.kr/ — connection reset through proxy on every attempt (3 rounds)
- 경상남도 합천군 (48890): https://www.hc.go.kr/ — www.hc.go.kr answers every path (/, /www/index.do, /main.do, /index.jsp) with an
- 제주특별자치도 제주시 (50110): https://www.jejusi.go.kr/ — www.jejusi.go.kr returns a WAF block page ('request contrary to the Web firewall
- 제주특별자치도 서귀포시 (50130): https://www.seogwipo.go.kr/ — WAF block page ('contrary to Web firewall security policies') on / and /index.ht
- 강원특별자치도 삼척시 (51230): https://www.samcheok.go.kr/ — www.samcheok.go.kr returns WAF block page (웹방화벽 보안정책 위배 차단, 삼척시 총무과 전산부서) for th
- 강원특별자치도 철원군 (51780): https://www.cwg.go.kr/ — connection resets, then TLS 'unable to get local issuer certificate' through pro
- 전북특별자치도 남원시 (52190): https://www.namwon.go.kr/ — every path on www.namwon.go.kr (/, /index.do, /index.do?contentsSid=5876) return

## 비워 둔 지역

- 없음

## 전체 목록

| 시/도 | 시/군/구 | 코드 | 상태 | URL | 비고 |
|---|---|---|---|---|---|
| 서울특별시 | 종로구 | 11110 | 안내 페이지(이전 확인) | https://www.jongno.go.kr/Main.do?menuNo=1365 |  |
| 서울특별시 | 중구 | 11140 | 안내 페이지(이전 확인) | https://junggu.seoul.kr/content.do?cmsid=14189 |  |
| 서울특별시 | 용산구 | 11170 | 메인(접속 불가, 미검증) | https://www.yongsan.go.kr/ | www.yongsan.go.kr: 'Empty reply from server' on https root and /portal/main/main |
| 서울특별시 | 성동구 | 11200 | 안내 페이지(이전 확인) | https://www.sd.go.kr/main/contents.do?key=1676 |  |
| 서울특별시 | 광진구 | 11215 | 안내 페이지(이전 확인) | https://www.gwangjin.go.kr/portal/main/contents.do?menuNo=200842 |  |
| 서울특별시 | 동대문구 | 11230 | 안내 페이지(이전 확인) | https://www.ddm.go.kr/www/contents.do?key=860 |  |
| 서울특별시 | 중랑구 | 11260 | 안내 페이지(이전 확인) | https://www.jungnang.go.kr/portal/main/contents.do?menuNo=200052 |  |
| 서울특별시 | 성북구 | 11290 | 안내 페이지(이전 확인) | https://www.sb.go.kr/www/selectBbsNttView.do?key=5927&bbsNo=91&nttNo=9502169 |  |
| 서울특별시 | 강북구 | 11305 | 메인 폴백(봇 차단) | https://www.gangbuk.go.kr/ | homepage returns sabFingerPrint bot-check page; cannot crawl |
| 서울특별시 | 도봉구 | 11320 | 안내 페이지(이전 확인) | https://www.dobong.go.kr/subsite/waste/Contents.asp?code=10007366 |  |
| 서울특별시 | 노원구 | 11350 | 안내 페이지(이전 확인) | https://www.nowon.kr/www/info/info5/minwon4_03/minwon4_03_04.jsp |  |
| 서울특별시 | 은평구 | 11380 | 안내 페이지(이전 확인) | https://www.ep.go.kr/www/contents.do?key=1239 |  |
| 서울특별시 | 서대문구 | 11410 | 안내 페이지(이전 확인) | https://www.sdm.go.kr/civil/type/recycle.do |  |
| 서울특별시 | 마포구 | 11440 | 안내 페이지(이전 확인) | https://www.mapo.go.kr/site/main/content/mapo05060501 |  |
| 서울특별시 | 양천구 | 11470 | 안내 페이지(이전 확인) | https://www.yangcheon.go.kr/common/files/DownloadViewFile.do?cfIdx=CF00009413&cfGroup=COMMON&cfRename=c3af142f-7824-491d-9653-1dcb7fb94703.pdf |  |
| 서울특별시 | 강서구 | 11500 | 안내 페이지(이전 확인) | https://www.gangseo.seoul.kr/env/env010101 |  |
| 서울특별시 | 구로구 | 11530 | 안내 페이지(이전 확인) | https://www.guro.go.kr/www/contents.do?key=2697 |  |
| 서울특별시 | 금천구 | 11545 | 안내 페이지(이전 확인) | https://www.geumcheon.go.kr/portal/contents.do?key=821 |  |
| 서울특별시 | 영등포구 | 11560 | 안내 페이지(이전 확인) | https://www.ydp.go.kr/www/contents.do?key=2733 |  |
| 서울특별시 | 동작구 | 11590 | 안내 페이지(이전 확인) | https://www.dongjak.go.kr/portal/main/contents.do?menuNo=200592 |  |
| 서울특별시 | 관악구 | 11620 | 안내 페이지(이전 확인) | https://www.gwanak.go.kr/site/gwanak/07/10703010200002016051206.jsp |  |
| 서울특별시 | 서초구 | 11650 | 안내 페이지(이전 확인) | https://www.seocho.go.kr/site/seocho/04/10408030301002015070706.jsp |  |
| 서울특별시 | 강남구 | 11680 | 안내 페이지(이전 확인) | https://www.gangnam.go.kr/board/waste/list.do?mid=ID02_011109 |  |
| 서울특별시 | 송파구 | 11710 | 안내 페이지(이전 확인) | https://www.songpa.go.kr/www/contents.do?key=3164 |  |
| 서울특별시 | 강동구 | 11740 | 안내 페이지(이전 확인) | https://www.gangdong.go.kr/web/newportal/contents/gdp_005_004_010_004_001 |  |
| 전남광주통합특별시 | 목포시 | 12110 | 안내 페이지 | https://www.mokpo.go.kr/www/life_welfare/environmental_info/waste_garbage | 크롤러: 폐기물 배출·쓰레기종량제 |
| 전남광주통합특별시 | 여수시 | 12130 | 안내 페이지 | https://www.yeosu.go.kr/www/sphere/environ/waste | 크롤러: 생활폐기물 |
| 전남광주통합특별시 | 순천시 | 12150 | 메인(접속 불가, 미검증) | https://www.suncheon.go.kr/ | TLS connection reset by peer on every attempt (root, /kr/, http variant); domain |
| 전남광주통합특별시 | 나주시 | 12170 | 안내 페이지 | https://www.naju.go.kr/www/field_info/environment/waste_new | 크롤러: 생활폐기물 배출 |
| 전남광주통합특별시 | 광양시 | 12190 | 안내 페이지 | https://gwangyang.go.kr/menu.es?mid=a11205090101 | homepage /kor nav link 생활폐기물 → 배출요령 page; www host has no DNS, bare gwangyang.go |
| 전남광주통합특별시 | 동구 | 12210 | 안내 페이지 | https://www.donggu.kr/menu.es?mid=a10408010300 | homepage menu 청소/환경 > 생활폐기물 배출안내 > 재활용 (품목별 분리배출 요령); host resets on first conne |
| 전남광주통합특별시 | 서구 | 12240 | 안내 페이지 | https://www.seogu.gwangju.kr/menu.es?mid=a10308020100 | homepage menu 분야별정보>도시/환경/위생>재활용>재활용품처리 정보 (hits 분리배출/배출방법/재활용품); site intermitt |
| 전남광주통합특별시 | 남구 | 12270 | 안내 페이지 | https://www.namgu.gwangju.kr/menu.es?mid=a10501050000 | 생활정보 > 청소 > 재활용품 관리 (재검토로 교체) |
| 전남광주통합특별시 | 북구 | 12300 | 안내 페이지 | https://bukgu.gwangju.kr/menu.es?mid=a10406060000 | 쓰레기 배출요령(다국어안내) 페이지지만 본문은 한국어 배출요령 |
| 전남광주통합특별시 | 광산구 | 12330 | 안내 페이지 | https://www.gwangsan.go.kr/contentsView.do?pageId=www402 | 크롤러: 생활쓰레기 |
| 전남광주통합특별시 | 담양군 | 12710 | 메인 폴백 | https://www.damyang.go.kr/index.damyang | home ok; sitemap 환경 section has only 대형폐기물/불법투기/EPR pages; site search '분리배출' re |
| 전남광주통합특별시 | 곡성군 | 12720 | 안내 페이지 | https://www.gokseong.go.kr/kr/subPage.do?menuNo=103004002003 | sitemap → 폐기물 → 종량제규격봉투 (생활쓰레기 처리방법 Q&A, 재활용품 배출); TLS needed Thawte TLS RSA CA  |
| 전남광주통합특별시 | 구례군 | 12730 | 메인(접속 불가, 미검증) | https://www.gurye.go.kr/ | proxy gateway 502 on CONNECT to www.gurye.go.kr and gurye.go.kr (retried); gurye |
| 전남광주통합특별시 | 고흥군 | 12740 | 안내 페이지 | https://www.goheung.go.kr/environmental/contentsView.do?pageId=environmental16 | 크롤러: 폐기물배출 |
| 전남광주통합특별시 | 보성군 | 12750 | 안내 페이지 | https://www.boseong.go.kr/www/open_data/environment/recycle | homepage redirects to plain-http intro (unreachable via proxy); https://www.bose |
| 전남광주통합특별시 | 화순군 | 12760 | 안내 페이지 | https://www.hwasun.go.kr/contents.do?S=S01&M=060804010000 | menu 생활복지>환경정보>폐기물관련정보>배출방법; root https:// redirects to http intro.do (unreachab |
| 전남광주통합특별시 | 장흥군 | 12770 | 안내 페이지 | https://www.jangheung.go.kr/www/open_data/life_environment/separate_collection | 크롤러: 분리수거안내 |
| 전남광주통합특별시 | 강진군 | 12780 | 메인(접속 불가, 미검증) | https://www.gangjin.go.kr/ | connection reset through proxy on every attempt (www and bare host, 3 rounds); c |
| 전남광주통합특별시 | 해남군 | 12790 | 안내 페이지 | https://www.haenam.go.kr/index.9is?contentUid=8ae590de8dcaf22e018dce5afaa72146 | homepage 전체메뉴 분야별업무>환경>생활폐기물>재활용품 분리배출 요령 (sibling: 생활폐기물 배출 방법 contentUid=8ae59 |
| 전남광주통합특별시 | 영암군 | 12800 | 안내 페이지 | https://www.yeongam.go.kr/home/www/info_area/life_env/life_env_01/life_env_01_05/yeongam.go | homepage(intro)->/home/www; 분야별정보>환경>환경정보>생활폐기물처리 (hits 분리배출/배출방법/종량제) |
| 전남광주통합특별시 | 무안군 | 12810 | 안내 페이지 | https://www.muan.go.kr/www/information/environment_facilities/recycling/waste | 크롤러: 생활쓰레기 |
| 전남광주통합특별시 | 함평군 | 12820 | 안내 페이지 | https://www.hampyeong.go.kr/boardList.do?boardId=GARBAGE_DISPOSAL&pageId=www653 | menu 환경/위생>환경정보>올바른 쓰레기 배출방법 (종량제 봉투 배출 가이드 목록) |
| 전남광주통합특별시 | 영광군 | 12830 | 안내 페이지 | https://www.yeonggwang.go.kr/subpage/?site=headquarter_new&mn=9117 | main nav 환경 → 쓰레기 재활용 landing (종량제/재활용 intro, tabs per material); tab mn=9118 고철 |
| 전남광주통합특별시 | 장성군 | 12840 | 안내 페이지 | https://www.jangseong.go.kr/home/www/openinfo/environment/environment_21/show/59 | homepage menu 분야별정보>환경정보>청소행정>생활폐기물, 재활용품쓰레기 tab has 재활용품 배출요령 table |
| 전남광주통합특별시 | 완도군 | 12850 | 안내 페이지 | https://www.wando.go.kr/wando/sub.cs?m=548 | homepage JS-redirects to /wando/index.cs; menu 생활복지>위생환경>생활폐기물>쓰레기종량제란 (분리배출/배출방 |
| 전남광주통합특별시 | 진도군 | 12860 | 안내 페이지 | https://www.jindo.go.kr/home/sub.cs?m=334 | menu 분야별정보>환경/상·하수도>생활환경정보 (생활쓰레기 배출방법 표 + 종량제봉투 가격) |
| 전남광주통합특별시 | 신안군 | 12870 | 안내 페이지 | https://www.shinan.go.kr/home/www/dept_info/env/waste/page.wscms | main page nav 폐기물관련정보 → landing is 쓰레기분리수거안내 (waste_01) |
| 부산광역시 | 중구 | 26110 | 안내 페이지 | https://www.bsjunggu.go.kr/index.junggu?menuCd=DOM_000000109001001001 | sitemap > 청소/환경/식품 > 청소 > 쓰레기처리안내 > 생활쓰레기배출; https works (crawler DNS failure wa |
| 부산광역시 | 서구 | 26140 | 안내 페이지 | https://www.bsseogu.go.kr/index.bsseogu;jsessionid=23585A9ED0A17AF35B5E210E4E6AB9D8.tomcat2?menuCd=DOM_000000102004002006 | 크롤러: 생활쓰레기 배출 요령 |
| 부산광역시 | 동구 | 26170 | 안내 페이지 | https://www.bsdonggu.go.kr/index.donggu?menuCd=DOM_000000104005002000 | 크롤러: 쓰레기분리배출요령 |
| 부산광역시 | 영도구 | 26200 | 안내 페이지 | https://www.yeongdo.go.kr/00672/01898/00863.web | 크롤러: 생활쓰레기 배출안내 |
| 부산광역시 | 부산진구 | 26230 | 안내 페이지 | https://www.busanjin.go.kr/index.busanjin?menuCd=DOM_000000105006002003 | homepage intro -> /index.busanjin; menu 행정>청소>생활폐기물>재활용품 배출 및 분리수거요령 |
| 부산광역시 | 동래구 | 26260 | 안내 페이지 | https://www.dongnae.go.kr/index.dongnae?menuCd=DOM_000000105009001004 | menu 분야별정보>청소/환경/식품>청소>재활용품 분리요령 (home / redirects via JS to contentsSid=2073) |
| 부산광역시 | 남구 | 26290 | 안내 페이지 | https://www.bsnamgu.go.kr/index.namgu?menuCd=DOM_000003501000000000 | main nav 쓰레기배출안내 (DOM_000000125001012000) redirects to 자원순환 종합포털 /clean page |
| 부산광역시 | 북구 | 26320 | 안내 페이지 | https://www.bsbukgu.go.kr/index.bsbukgu?menuCd=DOM_000000103005001003 | homepage menu 분야별정보>청소/환경/위생>생활쓰레기 배출안내 (sibling 재활용품분리배출요령 menuCd=DOM_000000103 |
| 부산광역시 | 해운대구 | 26350 | 안내 페이지 | https://www.haeundae.go.kr/index.do?menuCd=DOM_000000102014001000 | homepage JS-redirects to /index.do; menu 행정>청소>생활쓰레기 배출 안내 |
| 부산광역시 | 사하구 | 26380 | 안내 페이지 | https://www.saha.go.kr/portal/contents.do?mId=0405050000 | menu 분야별정보>환경/청소>폐기물>생활폐기물처리안내>생활쓰레기 배출요령 (same content at mId=0405050101) |
| 부산광역시 | 금정구 | 26410 | 안내 페이지 | https://www.geumjeong.go.kr/index.geumj?menuCd=DOM_000000133007000000 | sitemap → 청소/환경/위생 → 생활쓰레기 분리배출 |
| 부산광역시 | 강서구 | 26440 | 안내 페이지 | https://www.bsgangseo.go.kr/portal/contents.do?mid=0304010100 | 크롤러: 쓰레기분리배출 |
| 부산광역시 | 연제구 | 26470 | 안내 페이지 | https://www.yeonje.go.kr/portal/contents.do?mId=0602020100 | 크롤러: 쓰레기배출안내 |
| 부산광역시 | 수영구 | 26500 | 메인(접속 불가, 미검증) | https://www.suyeong.go.kr/ | www.suyeong.go.kr: connection reset / empty reply on https root and /index.suyeo |
| 부산광역시 | 사상구 | 26530 | 안내 페이지 | https://www.sasang.go.kr/index.sasang?menuCd=DOM_000000110001001000 | 크롤러: 생활쓰레기안내 |
| 부산광역시 | 기장군 | 26710 | 안내 페이지 | https://www.gijang.go.kr/index.gijang?menuCd=DOM_000000104006001003 | menu 분야별정보>청소/환경>청소/재활용>재활용 (재활용품 분리배출요령); sibling 일반쓰레기 (…001001) covers 종량제 배출 |
| 대구광역시 | 중구 | 27110 | 메인(접속 불가, 미검증) | https://www.jung.daegu.kr/ | www.jung.daegu.kr answers HTTP 400 Bad Request (1.4KB WAF-style page) for / and  |
| 대구광역시 | 동구 | 27140 | 안내 페이지 | https://www.dong.daegu.kr/portal/contents.do?mid=0405130000 | main nav 분야별정보 > 환경 > 쓰레기 분리배출 (sub: 생활쓰레기/재활용품 0405130400) |
| 대구광역시 | 서구 | 27170 | 안내 페이지 | https://www.dgs.go.kr/portal/contents.do?mid=0207090000 | homepage menu 종합민원>환경>재활용 분리배출 안내 (sibling 일반쓰레기 배출 안내 mid=0207080000); registry |
| 대구광역시 | 남구 | 27200 | 안내 페이지 | https://www.nam.daegu.kr/index.do?menu_id=00000777 | homepage menu 생활정보>위생/환경>청소/재활용>재활용쓰레기 배출; sibling 생활쓰레기 배출 (menu_id=00000776) a |
| 대구광역시 | 북구 | 27230 | 안내 페이지 | https://www.buk.daegu.kr/index.do?menu_id=00001791 | menu 환경/청소>청소/재활용>생활쓰레기배출방법 (재활용품분리배출안내 menu_id=00001795) |
| 대구광역시 | 수성구 | 27260 | 안내 페이지 | https://www.suseong.kr/index.do?menu_id=00042540 | main nav 쓰레기 배출 안내 (menu_id=00000359) redirects to 00042540 쓰레기 배출 방법 |
| 대구광역시 | 달서구 | 27290 | 안내 페이지 | https://www.dalseo.daegu.kr/index.do?menu_id=00001251 | homepage menu 청소 > 쓰레기 배출 및 수거방법 (sibling 재활용품 분리배출 menu_id=00001252) |
| 대구광역시 | 달성군 | 27710 | 안내 페이지 | https://www.dalseong.daegu.kr/index.do?menu_id=00000365 | menu 위생·환경>청소>쓰레기 종량제 (single page with 종량제/분리배출/대형폐기물 sections) |
| 대구광역시 | 군위군 | 27720 | 안내 페이지 | https://www.gunwi.go.kr/ko/page.do?mnu_uid=303& | menu 분야별정보>환경/위생>청소행정>재활용품/대형폐기물 (종량제봉투 page mnu_uid=301) |
| 인천광역시 | 제물포구 | 28125 | 안내 페이지 | https://www.jemulpo.go.kr/main/area/clean/waste_living.jsp | main nav 분야별정보 > 청소/환경 > 쓰레기/재활용 > 생활쓰레기 (new district site jemulpo.go.kr) |
| 인천광역시 | 영종구 | 28155 | 안내 페이지 | https://www.yeongjong.go.kr/main/content/view.do?sn=276 | homepage menu 환경/청소 > 쓰레기배출요령 (sibling 재활용 실천 및 배출 sn=288, 쓰레기종량제 sn=280); new d |
| 인천광역시 | 미추홀구 | 28177 | 안내 페이지 | https://www.michuhol.go.kr/main/content.do?sq=446 | menu 환경/청소>쓰레기배출방법>재활용품 tab (sq=443 일반쓰레기 is the section landing); domain michuh |
| 인천광역시 | 연수구 | 28185 | 안내 페이지 | https://www.yeonsu.go.kr/main/part/clean/recycle.asp | menu 분야별정보>청소/환경>재활용품 배출방법 |
| 인천광역시 | 남동구 | 28200 | 안내 페이지 | https://www.namdong.go.kr/main/area/clean/garbage.jsp | main nav 청소/환경 > 생활쓰레기배출; also recycle/intro.jsp 재활용품 분리배출요령 |
| 인천광역시 | 부평구 | 28237 | 안내 페이지 | https://www.icbp.go.kr/main/life/clean/separation_waste.jsp | homepage 전체메뉴 분야별정보>생활정보>폐기물 종량제>올바른 쓰레기 분리배출 (siblings 일반 생활쓰레기 life_garbage.js |
| 인천광역시 | 계양구 | 28245 | 메인(접속 불가, 미검증) | https://www.gyeyang.go.kr/ | https://www.gyeyang.go.kr/ and /open_content/main/ reset the TLS connection on 3 |
| 인천광역시 | 서해구 | 28275 | 안내 페이지 | https://www.seohae.go.kr/open_content/main/part/clean/detritus.jsp | menu 정보>환경/쓰레기>청소/쓰레기>생활쓰레기 배출 (재활용쓰레기 배출 detritus_recycle.jsp); 서해구 = 구 서구 신규 도 |
| 인천광역시 | 검단구 | 28290 | 안내 페이지 | https://www.geomdan.go.kr/main/part/clean/detritus.jsp | main nav 환경/쓰레기 > 청소/쓰레기 > 생활쓰레기 배출 (sub detritus_recycle.jsp 재활용쓰레기 배출) |
| 인천광역시 | 강화군 | 28710 | 안내 페이지 | https://www.ganghwa.go.kr/main/part/clean/detritus.jsp | homepage 전체메뉴 분야별정보>환경위생>생활쓰레기 (sibling 재활용쓰레기 detritus_recycle.jsp) |
| 인천광역시 | 옹진군 | 28720 | 안내 페이지 | https://www.ongjin.go.kr/open_content/main/environment/cleaning/excretion.jsp | menu 살기좋은옹진>환경/청소>쓰레기배출안내>생활쓰레기 배출방법; sibling recycle.jsp 재활용품 also ok |
| 대전광역시 | 동구 | 30110 | 안내 페이지 | https://www.donggu.go.kr/dg/kor/contents/618 | menu 분야별정보>환경/쓰레기>재활용품배출안내>재활용품 분리배출방법 (가정쓰레기배출 contents/168) |
| 대전광역시 | 중구 | 30140 | 안내 페이지 | https://www.djjunggu.go.kr/kr/sub06_05_09_01.do | main nav 분야별정보 > 환경/생활 > 쓰레기배출요령 |
| 대전광역시 | 서구 | 30170 | 안내 페이지 | https://seogu.go.kr/kor/sub06_11_01_01.do | sitemap 분야별정보>환경청소>생활폐기물 배출안내>생활쓰레기배출 (sibling 재활용품분리배출 sub06_11_02_01.do); www. |
| 대전광역시 | 유성구 | 30200 | 안내 페이지 | https://www.yuseong.go.kr/kor/sub07_11_03_03.do | homepage intro -> /kor/; menu 분야별정보>환경>쓰레기>재활용품배출안내; sibling sub07_11_03_09 생활쓰레 |
| 대전광역시 | 대덕구 | 30230 | 안내 페이지 | https://www.daedeok.go.kr/was/goContents.do?link=/was/was01/WAS0102&menuId=WAS0102 | main site links 생활폐기물배출신고 -> /was subsite 생활폐기물배출안내 (배출방법/재활용품/종량제; 분리배출요령 WAS01 |
| 울산광역시 | 중구 | 31110 | 안내 페이지 | https://www.junggu.ulsan.kr/index.ulsan?menuCd=DOM_000000105005013001 | main nav 생활폐기물처리 (DOM_000000105005013000) → 일반쓰레기 배출안내 tab; hits 재활용품/종량제 |
| 울산광역시 | 남구 | 31140 | 안내 페이지 | https://www.ulsannamgu.go.kr/fieldInfo/recyclingWaste01.jsp | easyMain 쓰레기ㆍ환경 menu > 재활용품 분리배출 (sibling 생활쓰레기 fieldInfo/garbageWaste01.jsp) |
| 울산광역시 | 동구 | 31170 | 안내 페이지 | https://www.donggu.ulsan.kr/donggu/contents/contents.do?mId=7050201 | menu 분야별정보>환경·쓰레기>재활용쓰레기>재활용분리배출; sibling mId=7050101 생활쓰레기 (종량제) also ok |
| 울산광역시 | 북구 | 31200 | 안내 페이지 | https://www.bukgu.ulsan.kr/lay1/S1T211C364/contents.do | menu 분야별정보>환경/위생>재활용품>재활용배출방법; 생활쓰레기 page S1T192C208 |
| 울산광역시 | 울주군 | 31710 | 안내 페이지 | https://www.ulju.ulsan.kr/ulju/contents.do?mId=0505010100 | main nav 분야별정보 > 환경/교통 > 생활폐기물배출방법 > 생활쓰레기 |
| 세종특별자치시 | 세종특별자치시 | 36110 | 안내 페이지 | https://www.sejong.go.kr/recycle/sub03_01_01_01.do | root / redirects to SSO; kor.do main → 자원순환홈페이지 (/recycle) > 생활폐기물 분리배출 |
| 경기도 | 수원시 장안구 | 41111 | 안내 페이지 | https://www.suwon.go.kr/sw-www/deptHome/dep_env/env_03/env_03_11/env_03_01.jsp | root redirects to /tracer/checker.jsp (JS visitor check) but content pages load  |
| 경기도 | 수원시 권선구 | 41113 | 안내 페이지 | https://www.suwon.go.kr/sw-www/deptHome/dep_env/env_03/env_03_11/env_03_01.jsp | root redirects to /tracer/checker.jsp (JS visitor check) but content pages load  |
| 경기도 | 수원시 팔달구 | 41115 | 안내 페이지 | https://www.suwon.go.kr/sw-www/deptHome/dep_env/env_03/env_03_11/env_03_01.jsp | root redirects to /tracer/checker.jsp (JS visitor check) but content pages load  |
| 경기도 | 수원시 영통구 | 41117 | 안내 페이지 | https://www.suwon.go.kr/sw-www/deptHome/dep_env/env_03/env_03_11/env_03_01.jsp | root redirects to /tracer/checker.jsp (JS visitor check) but content pages load  |
| 경기도 | 성남시 수정구 | 41131 | 메인 폴백 | https://www.seongnam.go.kr/ | main site 환경·위생 section and sitemap have no 쓰레기/분리배출 content page; site search ( |
| 경기도 | 성남시 중원구 | 41133 | 메인 폴백 | https://www.seongnam.go.kr/ | main site 환경·위생 section and sitemap have no 쓰레기/분리배출 content page; site search ( |
| 경기도 | 성남시 분당구 | 41135 | 메인 폴백 | https://www.seongnam.go.kr/ | main site 환경·위생 section and sitemap have no 쓰레기/분리배출 content page; site search ( |
| 경기도 | 의정부시 | 41150 | 메인(접속 불가, 미검증) | https://www.ui4u.go.kr/ | curl 60: SSL certificate problem (unable to get local issuer certificate) on www |
| 경기도 | 안양시 만안구 | 41171 | 안내 페이지 | https://www.anyang.go.kr/main/contents.do?key=806 | intro → /main; nav 폐기물배출 (분리배출/배출요령/종량제 content) |
| 경기도 | 안양시 동안구 | 41173 | 안내 페이지 | https://www.anyang.go.kr/main/contents.do?key=806 | intro → /main; nav 폐기물배출 (분리배출/배출요령/종량제 content) |
| 경기도 | 부천시 원미구 | 41192 | 안내 페이지 | https://www.bucheon.go.kr/site/homepage/menu/viewMenu?menuid=148006007006001 | 분야별정보>환경·청소>올바른쓰레기배출>생활쓰레기 (sibling 재활용품 menuid=148006007006003); host resets of |
| 경기도 | 부천시 소사구 | 41194 | 안내 페이지 | https://www.bucheon.go.kr/site/homepage/menu/viewMenu?menuid=148006007006001 | 분야별정보>환경·청소>올바른쓰레기배출>생활쓰레기 (sibling 재활용품 menuid=148006007006003); host resets of |
| 경기도 | 부천시 오정구 | 41196 | 안내 페이지 | https://www.bucheon.go.kr/site/homepage/menu/viewMenu?menuid=148006007006001 | 분야별정보>환경·청소>올바른쓰레기배출>생활쓰레기 (sibling 재활용품 menuid=148006007006003); host resets of |
| 경기도 | 광명시 | 41210 | 안내 페이지 | https://www.gm.go.kr/pt/partInfo/en/cleaning/lfgarbage/PTMN219.jsp | menu 분야별정보>환경·에너지>청소>생활쓰레기 배출요령>재활용쓰레기 배출요령; sibling PTMN217 생활쓰레기 배출요령 also ok |
| 경기도 | 평택시 | 41220 | 안내 페이지 | https://www.pyeongtaek.go.kr/depart/contents.do?mid=0801010000 | menu 청소/환경/위생>청소/재활용>생활쓰레기배출요령 (재활용품배출요령 mid=0801030000) |
| 경기도 | 동두천시 | 41250 | 안내 페이지 | https://www.ddc.go.kr/ddc/contents.do?key=648 | main nav 생활쓰레기배출 > 일반쓰레기 배출 (sibling key=489 재활용품 배출) |
| 경기도 | 안산시 상록구 | 41271 | 안내 페이지 | https://www.ansan.go.kr/www/common/cntnts/selectContents.do?cntnts_id=C0001357 | homepage 전체메뉴 환경>재활용>재활용 품목 및 배출요령 (page has 일반/공동주택 분리배출 방법); site title generi |
| 경기도 | 안산시 단원구 | 41273 | 안내 페이지 | https://www.ansan.go.kr/www/common/cntnts/selectContents.do?cntnts_id=C0001357 | homepage 전체메뉴 환경>재활용>재활용 품목 및 배출요령 (page has 일반/공동주택 분리배출 방법); site title generi |
| 경기도 | 고양시 덕양구 | 41281 | 메인(접속 불가, 미검증) | https://www.goyang.go.kr/ | https://www.goyang.go.kr/ and /www/index.do reset TLS connection on 3 attempts ( |
| 경기도 | 고양시 일산동구 | 41285 | 메인(접속 불가, 미검증) | https://www.goyang.go.kr/ | https://www.goyang.go.kr/ and /www/index.do reset TLS connection on 3 attempts ( |
| 경기도 | 고양시 일산서구 | 41287 | 메인(접속 불가, 미검증) | https://www.goyang.go.kr/ | https://www.goyang.go.kr/ and /www/index.do reset TLS connection on 3 attempts ( |
| 경기도 | 과천시 | 41290 | 안내 페이지 | https://www.gccity.go.kr/dept/contents.do?mId=0604030200 | menu 환경/에너지/생활>생활쓰레기 배출 안내>재활용품 분리배출 요령 |
| 경기도 | 구리시 | 41310 | 안내 페이지 | https://www.guri.go.kr/www/contents.do?key=763 | main nav 자원행정·재활용 > 쓰레기 배출요령 (sibling key=765 재활용품 분리배출 요령) |
| 경기도 | 남양주시 | 41360 | 안내 페이지 | https://www.nyj.go.kr/www/contents.do?key=3004 | homepage 전체메뉴 분야별정보>환경>생활쓰레기 배출 정보>생활쓰레기 분리 배출 요령 |
| 경기도 | 오산시 | 41370 | 안내 페이지 | https://www.osan.go.kr/depart/contents.do?mId=0602010000 | homepage redirects to http main.do (https works); guides live on depart sub-site |
| 경기도 | 시흥시 | 41390 | 안내 페이지 | https://www.siheung.go.kr/portal/contents.do?mId=0703010300 | 분야별포털 환경/농어업>생활폐기물>재활용품 배출요령 (생활쓰레기 배출 요령 mId=0703010100 is image-only) |
| 경기도 | 군포시 | 41410 | 안내 페이지 | https://www.gunpo.go.kr/www/contents.do?key=4527 | 분야별정보 > 청소 > 쓰레기감량 및 재활용 안내 (재검토로 교체) |
| 경기도 | 의왕시 | 41430 | 안내 페이지 | https://www.uiwang.go.kr/UWKORENV0301 | homepage menu 청소정보 > 쓰레기배출방법 > 생활쓰레기 (sibling 재활용품 UWKORENV0303) |
| 경기도 | 하남시 | 41450 | 안내 페이지 | https://www.hanam.go.kr/www/contents.do?key=6421 | homepage intro -> /www/index.do; menu 환경/생활>청소>생활폐기물 배출 안내 (text has 배출요령/재활용품/종 |
| 경기도 | 용인시 처인구 | 41461 | 안내 페이지 | https://www.yongin.go.kr/home/www/www12/www12_08/www12_08_03/www12_08_03_03.jsp | sitemap 분야별정보>환경/녹지>생활폐기물>음식물쓰레기 및 재활용>재활용분리 배출요령 |
| 경기도 | 용인시 기흥구 | 41463 | 안내 페이지 | https://www.yongin.go.kr/home/www/www12/www12_08/www12_08_03/www12_08_03_03.jsp | sitemap 분야별정보>환경/녹지>생활폐기물>음식물쓰레기 및 재활용>재활용분리 배출요령 |
| 경기도 | 용인시 수지구 | 41465 | 안내 페이지 | https://www.yongin.go.kr/home/www/www12/www12_08/www12_08_03/www12_08_03_03.jsp | sitemap 분야별정보>환경/녹지>생활폐기물>음식물쓰레기 및 재활용>재활용분리 배출요령 |
| 경기도 | 파주시 | 41480 | 안내 페이지 | https://www.paju.go.kr/www/www_02/environment/environment_05/environment_05_01/environment_05_01_01.jsp | main nav 청소 > 생활쓰레기(폐기물); sibling environment_05_01_02.jsp 재활용품 배출요령 |
| 경기도 | 이천시 | 41500 | 안내 페이지 | https://www.icheon.go.kr/depart/contents.do?mid=0504040000 | 분야별정보>환경>생활폐기물>올바른 쓰레기 분리배출 방법 (sibling 재활용품 분리배출요령 mid=0504020000) |
| 경기도 | 안성시 | 41550 | 안내 페이지 | https://www.anseong.go.kr/depart/contents.do?mId=0702010000 | homepage quick link 폐기물안내 -> depart site 환경/상하수>생활폐기물>쓰레기배출안내 |
| 경기도 | 김포시 | 41570 | 안내 페이지 | https://www.gimpo.go.kr/portal/contents.do?key=2723 | menu 환경·위생·해양>쓰레기/폐기물>생활폐기물>생활쓰레기 (배출시간/종량제봉투별 배출방법/재활용품 분리배출) |
| 경기도 | 화성시 만세구 | 41591 | 안내 페이지 | https://www.hscity.go.kr/www/partInfo/trnsportEnvrn/trashProcessInfo.jsp | sitemap → 환경 landing → 쓰레기처리안내 (also 청소행정포털 h-waste.hscity.go.kr) |
| 경기도 | 화성시 효행구 | 41593 | 안내 페이지 | https://www.hscity.go.kr/www/partInfo/trnsportEnvrn/trashProcessInfo.jsp | sitemap → 환경 landing → 쓰레기처리안내 (also 청소행정포털 h-waste.hscity.go.kr) |
| 경기도 | 화성시 병점구 | 41595 | 안내 페이지 | https://www.hscity.go.kr/www/partInfo/trnsportEnvrn/trashProcessInfo.jsp | sitemap → 환경 landing → 쓰레기처리안내 (also 청소행정포털 h-waste.hscity.go.kr) |
| 경기도 | 화성시 동탄구 | 41597 | 안내 페이지 | https://www.hscity.go.kr/www/partInfo/trnsportEnvrn/trashProcessInfo.jsp | sitemap → 환경 landing → 쓰레기처리안내 (also 청소행정포털 h-waste.hscity.go.kr) |
| 경기도 | 광주시 | 41610 | 안내 페이지 | https://www.gjcity.go.kr/depart/contents.do?mId=0901010100 | sitemap 분야별정보>생활·환경>쓰레기 및 재활용>생활쓰레기 배출 (sibling 재활용품 배출 mId=0901050000); host re |
| 경기도 | 양주시 | 41630 | 안내 페이지 | https://www.yangju.go.kr/www/contents.do?key=689 | menu 분야별정보>환경·위생·청소>재활용품배출; sibling key=688 생활쓰레기배출 also ok |
| 경기도 | 포천시 | 41650 | 안내 페이지 | https://www.pocheon.go.kr/www/contents.do?key=4044 | menu 환경>생활쓰레기처리 (분리수거안내: 종량제/재활용품 배출요령) |
| 경기도 | 여주시 | 41670 | 메인(접속 불가, 미검증) | https://www.yeoju.go.kr/ | connection reset through proxy on every attempt (/, /main/yj, bare host; 4 round |
| 경기도 | 연천군 | 41800 | 안내 페이지 | https://www.yeoncheon.go.kr/www/contents.do?key=3502 | homepage 전체메뉴 > 생활쓰레기 배출요령 (sibling 재활용품 분리배출 key=3503) |
| 경기도 | 가평군 | 41820 | 안내 페이지 | https://www.gp.go.kr/portal/contents.do?key=2187 | menu 분야별정보>환경>쓰레기 배출안내>개요 (sub-pages 재활용품수거함 사용법, 종량제봉투 사용법, 투명페트병 분리배출); key=67 |
| 경기도 | 양평군 | 41830 | 안내 페이지 | https://www.yp21.go.kr/www/contents.do?key=1458 | menu 분야별정보>환경>청소민원>배출방법 (분리배출/종량제) |
| 충청북도 | 청주시 상당구 | 43111 | 안내 페이지 | https://www.cheongju.go.kr/www/contents.do?key=428 | intro.cheongju.go.kr → www.cheongju.go.kr/www; nav 청소/재활용 > 생활쓰레기배출방법 (also key= |
| 충청북도 | 청주시 서원구 | 43112 | 안내 페이지 | https://www.cheongju.go.kr/www/contents.do?key=428 | intro.cheongju.go.kr → www.cheongju.go.kr/www; nav 청소/재활용 > 생활쓰레기배출방법 (also key= |
| 충청북도 | 청주시 흥덕구 | 43113 | 안내 페이지 | https://www.cheongju.go.kr/www/contents.do?key=428 | intro.cheongju.go.kr → www.cheongju.go.kr/www; nav 청소/재활용 > 생활쓰레기배출방법 (also key= |
| 충청북도 | 청주시 청원구 | 43114 | 안내 페이지 | https://www.cheongju.go.kr/www/contents.do?key=428 | intro.cheongju.go.kr → www.cheongju.go.kr/www; nav 청소/재활용 > 생활쓰레기배출방법 (also key= |
| 충청북도 | 충주시 | 43130 | 안내 페이지 | https://www.chungju.go.kr/www/contents.do?key=3069 | homepage 전체메뉴 폐기물 처리 안내 > 생활폐기물 (sibling 재활용 가능자원 배출 key=657) |
| 충청북도 | 제천시 | 43150 | 안내 페이지 | https://www.jecheon.go.kr/www/contents.do?key=5155 | menu 분야별정보>환경>생활쓰레기>생활쓰레기 배출요령; key=497 쓰레기종량제 landing also ok |
| 충청북도 | 보은군 | 43720 | 안내 페이지 | https://www.boeun.go.kr/www/contents.do?key=1431 | menu 분야별정보>환경>쓰레기 배출 안내 (분리배출/종량제) |
| 충청북도 | 옥천군 | 43730 | 안내 페이지 | https://www.oc.go.kr/www/contents.do?key=337 | main nav 쓰레기 및 재활용 > 쓰레기배출요령 (sibling key=339 재활용품분리배출요령) |
| 충청북도 | 영동군 | 43740 | 안내 페이지 | https://www.yd21.go.kr/kr/html/sub05/05060301.html | homepage quick menu 생활/대형폐기물 배출요령 (siblings 재활용품 05060302.html, 쓰레기 종량제 05060303 |
| 충청북도 | 증평군 | 43745 | 안내 페이지 | https://www.jp.go.kr/kor/sub05_07_02.do | menu 분야별정보>환경/위생/산림/기타>재활용품분리배출; sibling sub05_07_01 생활쓰레기배출 also ok |
| 충청북도 | 진천군 | 43750 | 안내 페이지 | https://www.jincheon.go.kr/site/environment/sub.do?menukey=1518 | 환경/위생 subsite 쓰레기관련정보>생활쓰레기분리배출요령 (재활용분리배출요령 menukey=1517) |
| 충청북도 | 괴산군 | 43760 | 안내 페이지 | https://www.goesan.go.kr/trenv/contents.do?key=421 | sitemap → 교통/환경 subsite (/trenv) → 폐기물 정보 > 생활쓰레기 배출요령 |
| 충청북도 | 음성군 | 43770 | 안내 페이지 | https://www.eumseong.go.kr/www/contents.do?key=72 | homepage 전체메뉴 > 생활쓰레기 배출 방법 (sibling 재활용품 배출 방법 key=73) |
| 충청북도 | 단양군 | 43800 | 안내 페이지 | https://www.danyang.go.kr/dy21/856 | homepage menu 생활정보>환경정보>쓰레기배출요령 (분리수거 및 쓰레기 배출방법) |
| 충청남도 | 천안시 동남구 | 44131 | 안내 페이지 | https://www.cheonan.go.kr/kor/sub06_20_01.do | menu 분야별정보>자원순환>생활폐기물 (분리배출/종량제); root https:// redirects to http://www.cheonan. |
| 충청남도 | 천안시 서북구 | 44133 | 안내 페이지 | https://www.cheonan.go.kr/kor/sub06_20_01.do | menu 분야별정보>자원순환>생활폐기물 (분리배출/종량제); root https:// redirects to http://www.cheonan. |
| 충청남도 | 공주시 | 44150 | 안내 페이지 | https://www.gongju.go.kr/kr/sub06_08_06_01.do | intro → /kr; sitemap → 환경 section → 쓰레기분리배출 > 재활용분리배출 |
| 충청남도 | 보령시 | 44180 | 안내 페이지 | https://www.brcn.go.kr/kor/sub05_07_02_01.do | homepage 전체메뉴 분야별정보>교통·환경>쓰레기 배출요령 (sibling 재활용품 분리수거 sub05_07_08.do) |
| 충청남도 | 아산시 | 44200 | 안내 페이지 | https://www.asan.go.kr/main/cms/?no=293 | homepage(reset on first try) -> /main/; 분야별정보>환경>재활용배출안내; sibling no=292 일반쓰레기배출 |
| 충청남도 | 서산시 | 44210 | 안내 페이지 | https://www.seosan.go.kr/www/contents.do?key=1568 | menu 쓰레기배출정보>재활용품배출방법 (crawler hit selectWebLifewastemapView was a 수거운행 map, rep |
| 충청남도 | 논산시 | 44230 | 안내 페이지 | https://www.nonsan.go.kr/kor/html/sub05/05081101.html | main nav 분야별 정보 > 환경/위생 > 올바른 분리배출 방법 |
| 충청남도 | 계룡시 | 44250 | 안내 페이지 | https://gyeryong.go.kr/kr/html/sub05/05051401.html | homepage menu 분야별정보>환경/상하수도>폐기물 배출방법>생활폐기물 (page also has 재활용품 분리배출); www redire |
| 충청남도 | 당진시 | 44270 | 안내 페이지 | https://www.dangjin.go.kr/kor/sub05_06_04_01.do | menu 분야별정보>환경>청소도우미>생활/대형폐기물배출안내 (text has 분리배출/배출요령/재활용품/종량제) |
| 충청남도 | 금산군 | 44710 | 안내 페이지 | https://www.geumsan.go.kr/kr/html/sub05/05050602.html | menu 분야별정보>교통/환경>쓰레기종량제>재활용품배출요령 (쓰레기종량제란 05050601.html) |
| 충청남도 | 부여군 | 44760 | 안내 페이지 | https://www.buyeo.go.kr/html/kr/refo/refo_06040401.html | intro page quick link 생활폐기물배출안내 |
| 충청남도 | 서천군 | 44770 | 안내 페이지 | https://www.seocheon.go.kr/kor/sub06_09_02_02.do | homepage 전체메뉴 분야별정보>환경>쓰레기분리배출안내>생활쓰레기배출요령 (sub06_09_02_01 is 음식물쓰레기) |
| 충청남도 | 청양군 | 44790 | 안내 페이지 | https://www.cheongyang.go.kr/kor/sub06_04_03.do | homepage redirects to http kor.do (https works); menu 분야별정보>환경>쓰레기배출안내; sibling  |
| 충청남도 | 홍성군 | 44800 | 안내 페이지 | https://www.hongseong.go.kr/kor/sub05_090204.do | menu 분야별정보>환경>환경정보안내>쓰레기분리수거 |
| 충청남도 | 예산군 | 44810 | 안내 페이지 | https://www.yesan.go.kr/kor/sub06_10_06.do | intro → /kor; sitemap → 환경·수도 > 재활용분리수거안내 (main page itself often resets through |
| 충청남도 | 태안군 | 44825 | 안내 페이지 | https://www.taean.go.kr/life/sub04_08.do | life(복지/안전) subsite sitemap 환경 > 재활용품 (분리배출 품목/요령); siblings 생활쓰레기종량제 life/sub04 |
| 경상북도 | 포항시 남구 | 47111 | 안내 페이지 | https://www.pohang.go.kr/dept/contents.do?mid=0202010000 | homepage quick link 생활쓰레기 분리배출 -> dept site 환경>자원순환>생활쓰레기 종량제 및 배출요령 |
| 경상북도 | 포항시 북구 | 47113 | 안내 페이지 | https://www.pohang.go.kr/dept/contents.do?mid=0202010000 | homepage quick link 생활쓰레기 분리배출 -> dept site 환경>자원순환>생활쓰레기 종량제 및 배출요령 |
| 경상북도 | 경주시 | 47130 | 안내 페이지 | https://www.gyeongju.go.kr/area/page.do?mnu_uid=4412 | 분야별 area site 청소·환경·상하수도>쓰레기배출>생활쓰레기배출 (재활용품분리배출 mnu_uid=4509) |
| 경상북도 | 김천시 | 47150 | 메인(접속 불가, 미검증) | https://www.gc.go.kr/ | web firewall blocks the request (404 'contrary to the Web firewall security poli |
| 경상북도 | 안동시 | 47170 | 안내 페이지 | https://www.andong.go.kr/portal/contents.do?mId=0607030000 | homepage 전체메뉴 분야별정보>환경/청소>생활쓰레기 (sibling 재활용품배출요령 mId=0607090000) |
| 경상북도 | 구미시 | 47190 | 안내 페이지 | https://www.gumi.go.kr/life/contents.do?mid=0402010000 | homepage 생활/환경 sub-site (/life): 청소·생활>재활용>재활용품 분리 배출; sibling mid=0401060000 생활 |
| 경상북도 | 영주시 | 47210 | 안내 페이지 | https://www.yeongju.go.kr/open_content/main/page.do?mnu_uid=10512& | menu 분야별정보>자원 재활용>생활쓰레기 배출 |
| 경상북도 | 영천시 | 47230 | 메인(접속 불가, 미검증) | https://www.yc.go.kr/ | web firewall blocks the request (404 'contrary to the Web firewall security poli |
| 경상북도 | 상주시 | 47250 | 메인 폴백 | https://www.sangju.go.kr/main.tc | root is a maintenance/intro page (NetFunnel); main.tc, sitemap, 생활정보 subsite and |
| 경상북도 | 문경시 | 47280 | 안내 페이지 | https://www.gbmg.go.kr/portal/contents.do?mId=0606040106 | server omits Sectigo OV intermediate cert (curl 60) - verified with intermediate |
| 경상북도 | 경산시 | 47290 | 메인(접속 불가, 미검증) | https://www.gbgs.go.kr/open_content/ko/index.do | web application firewall returns 'request contrary to Web firewall security poli |
| 경상북도 | 의성군 | 47730 | 안내 페이지 | https://www.usc.go.kr/ko/page.do?mnu_uid=565 | main nav 분야별 정보 > 환경/위생 > 폐기물 (분리배출/배출요령/종량제 content on one page) |
| 경상북도 | 청송군 | 47750 | 메인(접속 불가, 미검증) | https://www.cs.go.kr/ | www.cs.go.kr web firewall blocks the proxy IP (HTTP 404 'contrary to the Web fir |
| 경상북도 | 영양군 | 47760 | 메인(접속 불가, 미검증) | https://www.yyg.go.kr/ | www.yyg.go.kr returns 404 'request contrary to the Web firewall security policie |
| 경상북도 | 영덕군 | 47770 | 메인(접속 불가, 미검증) | https://www.yd.go.kr/ | WAF block page ('contrary to Web firewall security policies') on root, 2 attempt |
| 경상북도 | 청도군 | 47820 | 메인(접속 불가, 미검증) | https://www.cheongdo.go.kr/ | web firewall blocks the request (404 'contrary to the Web firewall security poli |
| 경상북도 | 고령군 | 47830 | 메인(접속 불가, 미검증) | https://www.goryeong.go.kr/ | www.goryeong.go.kr web firewall blocks the proxy IP (HTTP 404 'contrary to the W |
| 경상북도 | 성주군 | 47840 | 안내 페이지 | https://www.sj.go.kr/page.do?mnu_uid=3954 | menu 분야별정보>자원순환>재활용분리배출; sibling mnu_uid=3953 생활쓰레기 배출 also ok |
| 경상북도 | 칠곡군 | 47850 | 메인(접속 불가, 미검증) | https://www.chilgok.go.kr/ | WAF block page ('contrary to Web firewall security policies') on root, 2 attempt |
| 경상북도 | 예천군 | 47900 | 안내 페이지 | https://www.ycg.kr/open.content/ko/section/environment/recycled/ | domain is ycg.kr (not ycg.go.kr); intro → /open.content/ko/; nav 환경 > 재활용품 (분리배출 |
| 경상북도 | 봉화군 | 47920 | 안내 페이지 | https://www.bonghwa.go.kr/depart/contents.do?mid=0802010000 | sitemap 분야별>환경>쓰레기배출>배출안내 (sibling 재활용안내 mid=0803000000) |
| 경상북도 | 울진군 | 47930 | 안내 페이지 | https://www.uljin.go.kr/index.uljin?menuCd=DOM_000000106003001003 | homepage intro -> index.uljin?contentsSid=1; menu 분야별정보>생활/환경>쓰레기처리>재활용품 분리배출; s |
| 경상북도 | 울릉군 | 47940 | 메인(접속 불가, 미검증) | https://www.ulleung.go.kr/ | WAF block page ('contrary to Web firewall security policies') on root, 2 attempt |
| 경상남도 | 창원시 의창구 | 48121 | 안내 페이지 | https://www.changwon.go.kr/cwportal/depart/11065/11084/13076.web | main quick link 쓰레기배출요령 (분리배출/배출요령/종량제 content) |
| 경상남도 | 창원시 성산구 | 48123 | 안내 페이지 | https://www.changwon.go.kr/cwportal/depart/11065/11084/13076.web | main quick link 쓰레기배출요령 (분리배출/배출요령/종량제 content) |
| 경상남도 | 창원시 마산합포구 | 48125 | 안내 페이지 | https://www.changwon.go.kr/cwportal/depart/11065/11084/13076.web | main quick link 쓰레기배출요령 (분리배출/배출요령/종량제 content) |
| 경상남도 | 창원시 마산회원구 | 48127 | 안내 페이지 | https://www.changwon.go.kr/cwportal/depart/11065/11084/13076.web | main quick link 쓰레기배출요령 (분리배출/배출요령/종량제 content) |
| 경상남도 | 창원시 진해구 | 48129 | 안내 페이지 | https://www.changwon.go.kr/cwportal/depart/11065/11084/13076.web | main quick link 쓰레기배출요령 (분리배출/배출요령/종량제 content) |
| 경상남도 | 진주시 | 48170 | 메인(접속 불가, 미검증) | https://www.jinju.go.kr/ | www.jinju.go.kr: connection reset by peer on every attempt (8 tries over ~20 min |
| 경상남도 | 통영시 | 48220 | 안내 페이지 | https://www.tongyeong.go.kr/00973/01112/01985.web | menu 생활/환경>쓰레기분리수거>재활용품 분리배출; sibling 01983.web 쓰레기분리 배출방법 also ok |
| 경상남도 | 사천시 | 48240 | 안내 페이지 | https://www.sacheon.go.kr/life/00330/01776.web | menu 생활쓰레기 배출요령; sibling 재활용품 배출은 이렇게 /life/00330/01781.web |
| 경상남도 | 김해시 | 48250 | 안내 페이지 | https://www.gimhae.go.kr/01544/02643/01737.web | https root 302s to plain http (unproxied); site search 분리배출 → 분야포털 환경위생 > 쓰레기처리  |
| 경상남도 | 밀양시 | 48270 | 안내 페이지 | https://www.miryang.go.kr/web/index.do?mnNo=50201010000 | homepage 전체메뉴 생활쓰레기 > 재활용품 분리배출 (menu mnNo=50201000000 redirects here); root is  |
| 경상남도 | 거제시 | 48310 | 메인(접속 불가, 미검증) | https://www.geoje.go.kr/ | TLS connection reset by peer on 3 attempts (proxy log: tunnel closed after 15s,  |
| 경상남도 | 양산시 | 48330 | 안내 페이지 | https://www.yangsan.go.kr/portal/contents.do?mid=0608010200 | menu 분야별정보>환경>생활폐기물 배출절차>재활용품 (생활폐기물(종량제봉투) mid=0608010100) |
| 경상남도 | 의령군 | 48720 | 메인(접속 불가, 미검증) | https://www.uiryeong.go.kr/ | connection reset through proxy on every attempt (www and bare host, 3 rounds) |
| 경상남도 | 함안군 | 48730 | 메인(접속 불가, 미검증) | https://www.haman.go.kr/ | proxy gateway 502 on CONNECT to www.haman.go.kr and haman.go.kr (retried); web s |
| 경상남도 | 창녕군 | 48740 | 메인(접속 불가, 미검증) | https://www.cng.go.kr/ | TLS connection reset by peer on 3 attempts (proxy log: tunnel closed after 15s,  |
| 경상남도 | 고성군 | 48820 | 메인(접속 불가, 미검증) | https://www.goseong.go.kr/ | HTTP 400 Bad Request (166B) on /, /main.do; /index.es resets; domain goseong.go. |
| 경상남도 | 남해군 | 48840 | 메인(접속 불가, 미검증) | https://www.namhae.go.kr/ | connection reset through proxy on every attempt (3 rounds) |
| 경상남도 | 하동군 | 48850 | 메인(접속 불가, 미검증) | https://www.hadong.go.kr/ | www.hadong.go.kr: connection reset by peer on every attempt (8 tries over ~25 mi |
| 경상남도 | 산청군 | 48860 | 메인(접속 불가, 미검증) | https://www.sancheong.go.kr | TLS connection reset by peer on 3 attempts (proxy log: tunnel closed after 15s,  |
| 경상남도 | 함양군 | 48870 | 메인(접속 불가, 미검증) | https://www.hygn.go.kr/ | proxy CONNECT tunnel failed 502 (gateway could not connect) on 3 attempts; domai |
| 경상남도 | 거창군 | 48880 | 메인(접속 불가, 미검증) | https://www.geochang.go.kr/ | connection reset through proxy on every attempt (3 rounds) |
| 경상남도 | 합천군 | 48890 | 메인(접속 불가, 미검증) | https://www.hc.go.kr/ | www.hc.go.kr answers every path (/, /www/index.do, /main.do, /index.jsp) with an |
| 제주특별자치도 | 제주시 | 50110 | 메인(접속 불가, 미검증) | https://www.jejusi.go.kr/ | www.jejusi.go.kr returns a WAF block page ('request contrary to the Web firewall |
| 제주특별자치도 | 서귀포시 | 50130 | 메인(접속 불가, 미검증) | https://www.seogwipo.go.kr/ | WAF block page ('contrary to Web firewall security policies') on / and /index.ht |
| 강원특별자치도 | 춘천시 | 51110 | 안내 페이지 | https://www.chuncheon.go.kr/cityhall/living-info/clean-environment/waste-discharge/general/ | main nav 생활정보 > 청소/환경 > 생활쓰레기배출요령 (redirects to /general/ tab) |
| 강원특별자치도 | 원주시 | 51130 | 안내 페이지 | https://www.wonju.go.kr/www/contents.do?key=543 | homepage 전체메뉴 분야별정보>기후/환경>폐기물 관리>폐기물 배출요령 (재활용가능 폐기물 배출방법, 종량제) |
| 강원특별자치도 | 강릉시 | 51150 | 안내 페이지 | https://www.gn.go.kr/www/contents.do?key=469 | menu 분야별정보>환경/생태/에너지>쓰레기&재활용>재활용품; sibling key=466 생활쓰레기 also ok |
| 강원특별자치도 | 동해시 | 51170 | 안내 페이지 | https://www.dh.go.kr/www/contents.do?key=792 | menu 환경>쓰레기처리>재활용분리수거 (일반쓰레기/종량제 key=790) |
| 강원특별자치도 | 태백시 | 51190 | 안내 페이지 | https://www.taebaek.go.kr/www/contents.do?key=1615 | intro.jsp → /www; nav 생활/환경 > 환경/쓰레기 > 재활용품 분리 배출 |
| 강원특별자치도 | 속초시 | 51210 | 안내 페이지 | https://www.sokcho.go.kr/sc/fields/environment/waste/disposal | sitemap 분야별정보>환경>쓰레기/폐기물>쓰레기/폐기물 처리 (일반 생활쓰레기 배출방법, 종량제봉투) |
| 강원특별자치도 | 삼척시 | 51230 | 메인(접속 불가, 미검증) | https://www.samcheok.go.kr/ | www.samcheok.go.kr returns WAF block page (웹방화벽 보안정책 위배 차단, 삼척시 총무과 전산부서) for th |
| 강원특별자치도 | 홍천군 | 51720 | 안내 페이지 | https://www.hongcheon.go.kr/www/contents.do?key=627 | menu 분야별정보>환경>생활쓰레기배출요령>일반쓰레기 (재활용품 key=628) |
| 강원특별자치도 | 횡성군 | 51730 | 안내 페이지 | https://www.hsg.go.kr/www/contents.do?key=1310 | root redirects to covid intro; /www/index.do nav 폐기물 > 폐기물배출요령 (sibling key=1311 |
| 강원특별자치도 | 영월군 | 51750 | 메인 폴백 | https://www.yw.go.kr/www/index.do | no household-waste guide page: sitemap/환경 section only has 대형폐기물처리(key=92), 자원재활 |
| 강원특별자치도 | 평창군 | 51760 | 안내 페이지 | https://www.pc.go.kr/portal/part/environment/waste/recycling | found via 누리집 지도 (sitemap): 분야별정보>환경>생활 폐기물>재활용분리배출요령; parent /environment/waste |
| 강원특별자치도 | 정선군 | 51770 | 안내 페이지 | https://www.jeongseon.go.kr/portal/partinfo/environment_forest/waste | menu 분야별정보>환경/산림>폐기물관리>쓰레기분리배출 안내 (same content at /waste/separationguide) |
| 강원특별자치도 | 철원군 | 51780 | 메인(접속 불가, 미검증) | https://www.cwg.go.kr/ | connection resets, then TLS 'unable to get local issuer certificate' through pro |
| 강원특별자치도 | 화천군 | 51790 | 안내 페이지 | https://www.ihc.go.kr/www/contents.do?key=298 | homepage 전체메뉴 분야별정보>산림/환경>폐기물관리>생활폐기물 배출안내 (분리배출 방법 표 + 종량제봉투) |
| 강원특별자치도 | 양구군 | 51800 | 안내 페이지 | https://www.yanggu.go.kr/user_sub?gfnc=www&mu_idx=526 | homepage menu 환경>재활용품 분리배출 요령 (site title tag is generic); sibling mu_idx=525 쓰레 |
| 강원특별자치도 | 인제군 | 51810 | 메인 폴백 | https://www.inje.go.kr/portal | home ok; portal sitemap/분야별정보 has no 청소·환경 waste menu; main page only banners to |
| 강원특별자치도 | 고성군 | 51820 | 안내 페이지 | https://www.gwgs.go.kr/kor/sub02_0804.do | main nav 생활정보 > 환경 > 생활쓰레기청소 |
| 강원특별자치도 | 양양군 | 51830 | 안내 페이지 | https://www.yangyang.go.kr/gw/portal/yyc_partinfo_envi_recy | 분야별정보>환경>폐기물 처리 및 재활용 landing; page has 생활폐기물 배출요령 (종량제봉투, 재활용품 품목별) after 건설/사업 |
| 전북특별자치도 | 전주시 완산구 | 52111 | 안내 페이지 | https://www.jeonju.go.kr/index.9is?contentUid=ff8080818990c349018b041acc483bef | menu 분야별정보>환경/청소/위생>청소>재활용품 분리수거 |
| 전북특별자치도 | 전주시 덕진구 | 52113 | 안내 페이지 | https://www.jeonju.go.kr/index.9is?contentUid=ff8080818990c349018b041acc483bef | menu 분야별정보>환경/청소/위생>청소>재활용품 분리수거 |
| 전북특별자치도 | 군산시 | 52130 | 안내 페이지 | https://www.gunsan.go.kr/main/m250 | menu 생활복지>청소>생활쓰레기 처리요령 |
| 전북특별자치도 | 익산시 | 52140 | 안내 페이지 | https://www.iksan.go.kr/eco/index.do?menuUid=ff8080819927194f01993687d24819c3 | main sitemap → 환경정보 subsite /eco → 생활폐기물배출안내 > 재활용가능 폐기물 (landing tab is 1회용 규제  |
| 전북특별자치도 | 정읍시 | 52180 | 메인 폴백 | https://www.jeongeup.go.kr/index.jeongeup | 전체메뉴/환경·위생 section and 자원순환과 dept page show no 생활쓰레기 배출 guide (only 관외 전입자 쓰레기 봉 |
| 전북특별자치도 | 남원시 | 52190 | 메인(접속 불가, 미검증) | https://www.namwon.go.kr/ | every path on www.namwon.go.kr (/, /index.do, /index.do?contentsSid=5876) return |
| 전북특별자치도 | 김제시 | 52210 | 안내 페이지 | https://www.gimje.go.kr/index.gimje?menuCd=DOM_000000106002003000 | menu link 환경/상하수도 > 쓰레기분리배출요령 (crawler rejected title due to 하수 keyword) |
| 전북특별자치도 | 완주군 | 52710 | 안내 페이지 | https://www.wanju.go.kr/index.9is?contentUid=ff8080818b024d8e018b274f72b42ca8 | intro → /index.9is; nav 환경/위생 > 생활폐기물 분리배출 (parent ...72702ca6, 쓰레기 배출요령 ...728f |
| 전북특별자치도 | 진안군 | 52720 | 안내 페이지 | https://www.jinan.go.kr/index.jinan?menuCd=DOM_000000109003007003 | sitemap 분야별정보>위생/환경/산림>환경정보>재활용 분리배출 요령 (sibling 생활폐기물 및 생활계유해폐기물 menuCd=DOM_000 |
| 전북특별자치도 | 무주군 | 52730 | 메인 폴백 | https://www.muju.go.kr/index.9is | homepage intro -> /index.9is; main site 사이트맵/분야별정보 has no 청소·쓰레기·분리배출 menu (only |
| 전북특별자치도 | 장수군 | 52740 | 안내 페이지 | https://www.jangsu.go.kr/index.jangsu?menuCd=DOM_000000106009001000 | menu 환경·위생>쓰레기종량제 (contains 분리배출 안내) |
| 전북특별자치도 | 임실군 | 52750 | 메인 폴백 | https://www.imsil.go.kr/index.imsil | main site has no 분리배출 guide menu: 분야별정보 sections are 복지/산업경제/농업귀농/재정/주소/비상대피/장학회 |
| 전북특별자치도 | 순창군 | 52770 | 안내 페이지 | https://www.sunchang.go.kr/index.do?menuUid=ff8080819a2f0e3b019ac95a4ae54b8f | homepage 전체메뉴 분야별정보>상하수도·환경>생활환경정보>생활쓰레기/재활용 (재활용품 배출요령) |
| 전북특별자치도 | 고창군 | 52790 | 안내 페이지 | https://www.gochang.go.kr/index.gochang?menuCd=DOM_000000104004001003 | homepage intro -> portal; menu 분야별정보>환경·상하수도>올바른 쓰레기 배출>재활용품 (text 분리배출/배출요령/재활용 |
| 전북특별자치도 | 부안군 | 52800 | 메인 폴백 | https://www.buan.go.kr/index.buan?contentsSid=1 | home ok; 환경/위생 section has only 음식물쓰레기 page (menuCd=DOM_000000104008009000); sit |
