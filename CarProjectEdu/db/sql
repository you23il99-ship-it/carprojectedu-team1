/* ==============================================================================
   CarProject - 01_schema.sql   (테이블 생성 스크립트)
   [실행 방법]
     방법1) MySQL Workbench : 이 파일 열기 -> 번개 아이콘(⚡) 클릭
     방법2) PowerShell (한 줄) :
            & "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p --default-character-set=utf8mb4 -e "source C:/Users/GRAM/Downloads/ClaudeJob/workspace_car/CarProject/db/01_schema.sql"
            주의 : PowerShell 은 < 입력 리다이렉션을 지원하지 않는다.
                   ( mysql -u root -p < 파일.sql  <- cmd 문법이라 PowerShell 에서 오류가 난다 )
                   그래서 mysql 클라이언트의 source 명령을 -e 옵션으로 실행한다.
   [실행 순서]
     01_schema.sql      (테이블 생성)  ->  02_sample_data.sql  (샘플 데이터)
   [주의] 아래 drop table 문이 있으므로, 이미 데이터가 있는 DB에서는 실행하지 마세요.
          처음 설치할 때만 사용합니다.
   ------------------------------------------------------------------------------
   [코드에서 역추론한 스키마 + 실무 기준 보강]
   기존 프로젝트에는 테이블 생성 SQL 파일이 없었습니다.
   그래서 DAO의 SQL문과 VO 클래스를 읽어 컬럼을 추출하고,
   아래 4가지를 실무 기준으로 보강했습니다.
     1. 비밀번호 컬럼을 VARCHAR(200)으로  : PBKDF2 해시값이 약 90자라서 필요
     2. 글번호/예약번호 AUTO_INCREMENT   : 기존 max(번호)+1 방식은 동시 등록 시 충돌
     3. 조회 조건 컬럼에 인덱스           : 데이터가 늘어날 때의 속도
     4. utf8mb4 문자셋                   : 이모지까지 저장 가능 (utf8은 3바이트라 이모지 깨짐)
   ============================================================================== */
/* ------------------------------------------------------------------
   0. 데이터베이스 생성
   ------------------------------------------------------------------
   utf8mb4          : 한글 + 이모지(4바이트) 저장 가능
   utf8mb4_unicode_ci : 대소문자 구분 없이 정렬/비교
   ------------------------------------------------------------------ */
create database if not exists rentcar_edu
    -- default 칸 — 고정 길이 글자 로 저장한다
    default character set utf8mb4
    collate utf8mb4_unicode_ci;
-- rentcar_edu 데이터베이스를 쓰겠다고 지정한다. 이 줄을 빠뜨리면 엉뚱한 DB 에 표가 만들어진다
use rentcar_edu;
/* 자식 테이블(참조하는 쪽)을 먼저 지운다 */
drop table if exists non_carorder;
-- fileboard 표가 이미 있으면 지운다. 처음부터 다시 만들기 위한 준비
drop table if exists fileboard;
-- board 표가 이미 있으면 지운다. 처음부터 다시 만들기 위한 준비
drop table if exists board;
-- member 표가 이미 있으면 지운다. 처음부터 다시 만들기 위한 준비
drop table if exists member;
-- carlist 표가 이미 있으면 지운다. 처음부터 다시 만들기 위한 준비
drop table if exists carlist;
/* ==============================================================================
   1. carlist  -  대여 가능한 차량 목록
   ==============================================================================
   사용하는 곳 : CarDAO.getAllCarList() / getCategoryList() / getOneCar()
   ============================================================================== */
create table carlist (
    -- carno 칸 — 정수 로 저장한다. 새 줄이 들어올 때마다 번호가 1씩 자동으로 올라간다. 비워 둘 수 없다
    carno         int             not null auto_increment  comment '차량번호(PK)',
    carname       varchar(50)     not null                 comment '차량명 (예: 아반떼)',
    carcompany    varchar(30)     not null                 comment '제조사 (예: 현대)',
    carprice      int             not null                 comment '1일 대여료(원)',
    carusepeople  int             not null                 comment '탑승 가능 인원',
    carinfo       varchar(500)        null                 comment '차량 설명',
    carimg        varchar(100)    not null                 comment '이미지 파일명 (webapp/img 폴더 안의 파일)',
    /* carcategory 는 CarController 에서 Small / Mid / Big 세 값만 사용한다.
       ENUM 으로 만들면 DB가 직접 다른 값을 거부해준다.
       (기존 varchar 였다면 'small', '소형', 'SMALL' 같은 값이 섞여 조회가 안 됐을 것) */
    carcategory   enum('Small','Mid','Big') not null       comment '차량 등급',
    -- 이 칸(들)으로 줄을 구분한다. 같은 값이 두 번 들어올 수 없다
    primary key (carno),
    /* CarList.jsp 의 등급별 검색(where carcategory=?)에 사용된다 */
    key idx_carlist_category (carcategory)
-- 표 만들기 끝. 한글이 깨지지 않도록 utf8mb4 로 지정한다
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_unicode_ci comment='차량 목록';
/* ==============================================================================
   2. member  -  회원
   ==============================================================================
   사용하는 곳 : MemberDAO (가입 / 중복확인 / 로그인 / 조회 / 수정 / 탈퇴)
   ============================================================================== */
create table member (
    -- 아이디 칸 — 글자 로 저장한다. 비워 둘 수 없다
    id        varchar(50)   not null  comment '아이디(PK)',
    /* [중요] 기존에는 비밀번호를 평문으로 저장했다.
       지금은 util.PasswordEncoder 가 만든 PBKDF2 해시를 저장한다.
           형식 : pbkdf2$120000${salt}$hash    (약 90자)
       그래서 넉넉하게 200자로 잡는다.
       (여기를 짧게 잡으면 해시가 잘려 저장되고, 로그인이 영구히 실패한다) */
    pass      varchar(200)  not null  comment '비밀번호(PBKDF2 해시)',
    -- 이름 칸 — 글자 로 저장한다. 비워 둘 수 없다
    name      varchar(50)   not null  comment '이름',
    email     varchar(100)      null  comment '이메일',
    reg_date  datetime      not null default current_timestamp comment '가입일시',
    age       int               null  comment '나이',
    gender    varchar(10)       null  comment '성별',
    address   varchar(300)      null  comment '주소(합쳐서 저장)',
    /* [기존 버그 수정] MemberVO 에는 tel / hp 필드가 있고 회원가입 화면에서도 입력받는데,
       MemberDAO.insertMember 의 INSERT문에 컬럼이 없어서 입력한 값이 버려졌다.
       컬럼을 만들어 실제로 저장하도록 한다. */
    tel       varchar(20)       null  comment '일반 전화번호',
    hp        varchar(20)       null  comment '휴대폰 번호',
    -- 이 칸(들)으로 줄을 구분한다. 같은 값이 두 번 들어올 수 없다
    primary key (id)
-- 표 만들기 끝. 한글이 깨지지 않도록 utf8mb4 로 지정한다
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_unicode_ci comment='회원';
/* ==============================================================================
   3. board  -  자유게시판 (계층형 : 답글이 부모글 아래에 들여쓰기되어 표시)
   ==============================================================================
   사용하는 곳 : BoardDAO
   [계층형 게시판 정렬 원리]
     b_group : 화면에 보이는 순서. 작을수록 위에 표시된다.
               새 글이 등록되면 기존 모든 글의 b_group 을 +1 하고 새 글은 0으로 넣는다.
     b_level : 들여쓰기 깊이. 원글 0, 답글 1, 답글의 답글 2 ...
   ============================================================================== */
create table board (
    /* [기존 문제] b_idx 를 코드에서 max(b_idx)+1 로 직접 계산했다.
       두 사람이 동시에 글을 쓰면 같은 번호가 만들어져 오류가 난다.
       AUTO_INCREMENT 는 DB가 번호를 겹치지 않게 보장한다. */
    b_idx      int           not null auto_increment  comment '글번호(PK)',
    -- b_id 칸 — 글자 로 저장한다
    b_id       varchar(50)       null  comment '작성자 아이디',
    b_pw       varchar(200)  not null  comment '글 비밀번호(해시. 레거시 평문도 허용)',
    b_name     varchar(50)   not null  comment '작성자 이름',
    b_email    varchar(100)      null  comment '작성자 이메일',
    b_title    varchar(200)  not null  comment '글 제목',
    /* varchar 대신 text : 게시글 본문 길이 제한을 두지 않는다 */
    b_content  text              null  comment '글 내용',
    -- 정렬순번 칸 — 정수 로 저장한다. 비워 둘 수 없다. 값을 안 넣으면 기본값이 들어간다
    b_group    int           not null default 0  comment '정렬 그룹 (작을수록 위)',
    b_level    int           not null default 0  comment '들여쓰기 깊이',
    b_date     datetime      not null default current_timestamp comment '작성일시',
    b_cnt      int           not null default 0  comment '조회수',
    -- 이 칸(들)으로 줄을 구분한다. 같은 값이 두 번 들어올 수 없다
    primary key (b_idx),
    /* order by b_group asc 정렬에 사용 */
    key idx_board_group (b_group),
    /* 작성자별 글 조회에 사용 */
    key idx_board_id (b_id)
    /* [FK를 걸지 않은 이유]
       b_id 에 member(id) 외래키를 걸면 회원 탈퇴 시 글이 남아 있어 삭제가 막힌다.
       "회원은 탈퇴하지만 글은 남긴다"는 게시판의 일반적인 정책이라 인덱스만 둔다. */
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_unicode_ci comment='자유게시판';
/* ==============================================================================
   4. fileboard  -  파일 첨부 게시판
   ==============================================================================
   사용하는 곳 : FileBoardDAO
   board 와 구조가 같고 첨부파일 관련 컬럼 3개가 추가된다.
   ============================================================================== */
create table fileboard (
    -- 글번호 칸 — 정수 로 저장한다. 새 줄이 들어올 때마다 번호가 1씩 자동으로 올라간다. 비워 둘 수 없다
    b_idx      int           not null auto_increment  comment '글번호(PK)',
    -- b_id 칸 — 글자 로 저장한다
    b_id       varchar(50)       null  comment '작성자 아이디',
    b_pw       varchar(200)  not null  comment '글 비밀번호(해시. 레거시 평문도 허용)',
    b_name     varchar(50)   not null  comment '작성자 이름',
    b_email    varchar(100)      null  comment '작성자 이메일',
    b_title    varchar(200)  not null  comment '글 제목',
    b_content  text              null  comment '글 내용',
    b_group    int           not null default 0  comment '정렬 그룹',
    b_level    int           not null default 0  comment '들여쓰기 깊이',
    b_date     datetime      not null default current_timestamp comment '작성일시',
    b_cnt      int           not null default 0  comment '조회수',
    /* 첨부파일 정보 : 여러 개면 세미콜론(;)으로 이어 붙여 저장한다.
       [원본명과 저장명을 나누는 이유]
         ofile(원본명) : 사용자가 올린 이름  ->  다운로드할 때 이 이름으로 내려준다
         sfile(저장명) : 서버 디스크에 저장된 이름  ->  UUID 로 새로 만든다
       기존 코드는 둘을 같은 값으로 저장해서
         - 다른 사람이 같은 파일명을 올리면 서로 덮어썼고
         - 파일명이 그대로 경로에 쓰여 경로 조작 공격의 통로가 됐다. */
    ofile      varchar(1000)     null  comment '원본 파일명 목록(; 구분)',
    sfile      varchar(1000)     null  comment '저장 파일명 목록(; 구분)',
    -- downcount 칸 — 정수 로 저장한다. 비워 둘 수 없다. 값을 안 넣으면 기본값이 들어간다
    downcount  int           not null default 0  comment '다운로드 횟수',
    -- 이 칸(들)으로 줄을 구분한다. 같은 값이 두 번 들어올 수 없다
    primary key (b_idx),
    key idx_fileboard_group (b_group),
    key idx_fileboard_id (b_id)
-- 표 만들기 끝. 한글이 깨지지 않도록 utf8mb4 로 지정한다
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_unicode_ci comment='파일 게시판';
/* ==============================================================================
   5. non_carorder  -  렌트 예약
   ==============================================================================
   사용하는 곳 : CarDAO.insertCarOrder() / getAllCarOrder() / getOneOrder()
                 carOrderUpdate() / OrderDelete()
   [테이블 이름이 non_ 으로 시작하는 이유]
     원래 "비회원(non-member) 예약" 테이블로 만들어졌기 때문이다.
     지금은 회원 예약도 이 테이블을 함께 쓴다.
   ============================================================================== */
create table non_carorder (
    -- non_orderid 칸 — 정수 로 저장한다. 새 줄이 들어올 때마다 번호가 1씩 자동으로 올라간다. 비워 둘 수 없다
    non_orderid    int          not null auto_increment  comment '예약번호(PK)',
    -- carno 칸 — 정수 로 저장한다. 비워 둘 수 없다
    carno          int          not null  comment '예약한 차량번호',
    carqty         int          not null default 1  comment '대여 수량',
    carreserveday  int          not null default 1  comment '대여 기간(일)',
    /* [기존] varchar 로 저장하고 조회할 때 str_to_date() 로 변환했다.
       그래서 '2026-13-99' 같은 값도 저장됐고, 변환 실패 시 조회에서 조용히 빠졌다.
       date 타입으로 두면 DB가 잘못된 날짜를 거부해준다. */
    carbegindate   date         not null  comment '대여 시작일',
    /* 옵션 선택 여부 : 1(선택) 또는 0(미선택).
       tinyint(1바이트) 로 두고 아래 CHECK 제약으로 0/1 만 허용한다.
       [참고] tinyint(1) 처럼 괄호로 표시 너비를 적으면 MySQL 8.0에서
              "1681 Integer display width is deprecated" 경고가 난다.
              저장 크기와 무관한 옛 표기법이라 지금은 괄호 없이 쓴다. */
    carins         tinyint      not null default 0  comment '자차보험',
    carwifi        tinyint      not null default 0  comment '무선 WiFi',
    carnave        tinyint      not null default 0  comment '네비게이션',
    carbabyseat    tinyint      not null default 0  comment '베이비시트',
    -- memberphone 칸 — 글자 로 저장한다. 비워 둘 수 없다
    memberphone    varchar(20)  not null  comment '예약 확인용 연락처',
    memberpass     varchar(200) not null  comment '예약 확인용 비밀번호(해시. 레거시 평문 허용)',
    /* [기존 버그 수정] CarController 는 회원 예약 시 vo.setId(회원아이디) 를 호출하지만
       CarDAO.insertCarOrder 의 INSERT문에 컬럼이 없어 회원 아이디가 저장되지 않았다.
       그래서 "내 예약 내역"을 아이디로 조회하는 것이 불가능했다. */
    member_id      varchar(50)      null  comment '회원 예약이면 회원 아이디, 비회원이면 NULL',
    /* [기존 문제] 총 결제금액을 저장하지 않고 화면에서만 계산했다.
       나중에 요금 정책이 바뀌면 과거 예약 금액을 재현할 수 없다.
       "그때 얼마를 결제했는가"는 반드시 함께 저장해야 한다. */
    total_price    int          not null default 0  comment '결제 총액(예약 당시 금액)',
    -- reg_date 칸 — 날짜와 시각 로 저장한다. 비워 둘 수 없다. 값을 안 넣으면 기본값이 들어간다
    reg_date       datetime     not null default current_timestamp comment '예약일시',
    -- 이 칸(들)으로 줄을 구분한다. 같은 값이 두 번 들어올 수 없다
    primary key (non_orderid),
    /* 예약 확인 화면은 연락처로 조회한다 (where memberphone=?) */
    key idx_order_phone (memberphone),
    key idx_order_member (member_id),
    /* 존재하지 않는 차량번호로 예약이 들어오는 것을 DB가 막아준다.
       on delete restrict : 예약이 남아 있는 차량은 삭제되지 않는다. */
    constraint fk_order_car foreign key (carno)
        -- 어느 표의 어느 칸과 연결되는지, 원본이 지워지면 어떻게 할지
        references carlist (carno) on delete restrict on update cascade,
    /* 옵션 값은 0 또는 1만 허용 (MySQL 8.0.16 이상에서 실제로 검사된다) */
    constraint chk_order_flags check (
        carins      in (0,1) and
        carwifi     in (0,1) and
        carnave     in (0,1) and
        carbabyseat in (0,1)
    )
-- 표 만들기 끝. 한글이 깨지지 않도록 utf8mb4 로 지정한다
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_unicode_ci comment='렌트 예약';
/* ------------------------------------------------------------------------------
   [주의 - NATURAL JOIN 관련]
   CarDAO.getAllCarOrder() 는 아래 SQL을 사용한다.
       select * from non_carorder natural join carlist where ...
   NATURAL JOIN 은 "두 테이블에서 이름이 같은 모든 컬럼"을 조인 조건으로 삼는다.
   지금은 carno 하나뿐이라 의도대로 동작한다.
   그래서 non_carorder 에 carprice, carname 처럼
   carlist 와 이름이 겹치는 컬럼을 추가하면 조인 조건이 하나 더 늘어나
   예약 조회 결과가 조용히 0건이 된다.  (그래서 금액 컬럼을 total_price 로 지었다)
   -> 4단계 작업에서 이 SQL을 명시적인 join ... on 으로 바꿔 이 위험을 없앤다.
   ------------------------------------------------------------------------------ */
/* 생성 결과 확인 */
show tables;