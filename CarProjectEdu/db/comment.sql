/* ==============================================================================
   03_comment.sql  -  자유게시판 댓글 기능 (무한 대댓글 + 추천)
   실행 방법 : MySQL Workbench 에서 이 파일을 열고 번개(⚡) 버튼으로 전체 실행
   실행 순서 : 01_schema.sql -> 02_sample_data.sql -> 03_comment.sql
   ------------------------------------------------------------------------------
   [왜 "답글(계층형 게시글)" 을 "댓글" 로 바꾸는가]
     기존 자유게시판은 답변을 "게시글" 로 저장했다.
       - board 테이블에 b_group / b_level 을 두고
       - 답변을 달 때마다 다른 글들의 b_group 을 전부 +1 하는 UPDATE 를 실행했다
     실무에서 이 방식을 쓰지 않는 이유
       1. 답변 하나를 달 때마다 관계없는 수천 건의 행을 UPDATE 한다 (글이 많아지면 느려진다)
       2. 답변도 "글" 이라서 목록의 페이지 수를 차지한다
          -> 원글 5건을 보려고 들어왔는데 답변 때문에 원글이 2건만 보인다
       3. 답변을 읽으려면 화면을 이동해야 한다 (대화 흐름이 끊긴다)
     그래서 답변은 별도 테이블(댓글)에 두고 글 상세 화면에서 바로 읽고 쓰게 한다.
     이것이 지금 대부분의 게시판이 쓰는 구조다.
   ------------------------------------------------------------------------------
   [무한 대댓글을 어떻게 표현하는가]
     parent_idx 컬럼 하나로 표현한다. 자기 테이블을 가리키는 외래키(self reference)다.
         c_idx  parent_idx  내용
         -----  ----------  ------------------
           1       NULL     좋은 정보 감사합니다      <- 최상위 댓글
           2         1      저도 궁금했어요            <- 1번의 답글
           3         2      같은 생각입니다            <- 2번의 답글 (답글의 답글)
           4       NULL     문의드립니다               <- 최상위 댓글
     이렇게 두면 깊이에 제한이 없다. 3단이든 10단이든 같은 방법으로 저장된다.
     화면에 보여줄 때 Java 가 부모-자식 관계로 묶어 트리로 만든다.
     (CommentService.getComments 참고)
   ------------------------------------------------------------------------------
   [추천을 왜 "숫자 하나"로 두지 않는가]
     board_comment 에 like_count 숫자만 두면 이렇게 된다.
         update board_comment set like_count = like_count + 1 where c_idx = ?
     문제 : 같은 사람이 100번 누르면 100이 된다. 취소도 할 수 없다.
     그래서 "누가 어느 댓글을 추천했는가" 를 board_comment_like 에 한 행씩 기록하고,
     추천 수는 그 행의 개수를 세서 구한다.
       - 같은 사람이 두 번 누르면 PK 중복이라 DB 가 막아준다
       - 다시 누르면 그 행을 지워 추천을 취소한다 (토글)
       - "내가 이미 추천했는지" 도 알 수 있어 버튼 색을 바꿀 수 있다
     [실무 참고] 댓글이 수십만 건이 되면 매번 개수를 세는 것이 부담이 된다.
                그때는 like_count 컬럼을 함께 두고 캐시처럼 쓴다(비정규화).
                다만 두 값이 어긋날 수 있어 정합성 관리가 필요하다.
                지금 규모에서는 세는 편이 단순하고 항상 정확하다.
   ============================================================================== */
use rentcar_edu;
/* Workbench 의 안전 모드(safe update) 때문에 where 절 없는 DML 이 막히는 것을 잠시 해제.
   (01/02 스크립트와 같은 이유. 끝에서 다시 켠다) */
set sql_safe_updates = 0;
/* 다시 실행할 수 있도록 기존 것을 지운다.
   자식(like) 테이블을 먼저 지워야 외래키 제약에 걸리지 않는다. */
drop table if exists board_comment_like;
-- board_comment 표가 이미 있으면 지운다. 처음부터 다시 만들기 위한 준비
drop table if exists board_comment;
/* ==============================================================================
   1. 댓글
   ============================================================================== */
create table board_comment (
    -- 댓글번호 칸 — 정수 로 저장한다. 새 줄이 들어올 때마다 번호가 1씩 자동으로 올라간다. 비워 둘 수 없다
    c_idx       int          not null auto_increment  comment '댓글번호(PK)',
    /* 어느 글의 댓글인가 */
    b_idx       int          not null  comment '원글 번호(board.b_idx)',
    /* 부모 댓글 번호. NULL 이면 최상위 댓글.
       값이 있으면 그 댓글에 대한 답글(대댓글)이다. 깊이 제한이 없다. */
    parent_idx  int              null  comment '부모 댓글번호(NULL=최상위)',
    /* 작성자 : 댓글은 로그인 회원만 쓸 수 있다 (비회원 비밀번호 방식을 쓰지 않는다) */
    c_id        varchar(50)  not null  comment '작성자 아이디',
    /* 작성 당시의 이름을 함께 저장한다.
       회원이 나중에 이름을 바꿔도 "그때 그 이름으로" 남아야 기록이 자연스럽다.
       (매번 member 테이블을 조인하지 않아도 되는 장점도 있다) */
    c_name      varchar(50)  not null  comment '작성자 이름(작성 당시)',
    -- c_content 칸 — 긴 글 로 저장한다. 비워 둘 수 없다
    c_content   text         not null  comment '댓글 내용',
    -- c_date 칸 — 날짜와 시각 로 저장한다. 비워 둘 수 없다. 값을 안 넣으면 기본값이 들어간다
    c_date      datetime     not null default current_timestamp  comment '작성일시',
    /* 수정한 적이 있으면 그 시각. 화면에 "(수정됨)" 을 표시하는 근거가 된다. */
    c_update    datetime         null  comment '마지막 수정일시(NULL=수정 안 함)',
    /* 소프트 삭제 : 실제로 지우지 않고 표시만 바꾼다.
       왜 물리 삭제를 하지 않는가
         대댓글이 달린 댓글을 지워버리면 자식 댓글들이 부모를 잃는다.
         (화면에서 어디에 붙여야 할지 알 수 없게 된다)
         그래서 자식이 있는 댓글은 "삭제된 댓글입니다" 로만 바꾸고 뼈대를 남긴다.
         자식이 없는 댓글은 그냥 지운다. (CommentService.deleteComment 참고) */
    del_flag    char(1)      not null default 'N'  comment '삭제 여부(Y/N)',
    -- 이 칸(들)으로 줄을 구분한다. 같은 값이 두 번 들어올 수 없다
    primary key (c_idx),
    /* 글 상세 화면은 항상 "이 글의 댓글" 을 조회한다 */
    key idx_comment_board (b_idx),
    key idx_comment_parent (parent_idx),
    /* 원글이 삭제되면 그 글의 댓글도 함께 사라져야 한다 -> cascade */
    constraint fk_comment_board foreign key (b_idx)
        -- 어느 표의 어느 칸과 연결되는지, 원본이 지워지면 어떻게 할지
        references board (b_idx) on delete cascade on update cascade,
    /* 자기 테이블을 가리키는 외래키(self reference).
       부모 댓글이 물리 삭제되면 자식도 함께 사라진다. */
    constraint fk_comment_parent foreign key (parent_idx)
        -- 어느 표의 어느 칸과 연결되는지, 원본이 지워지면 어떻게 할지
        references board_comment (c_idx) on delete cascade on update cascade,
    /* 삭제 여부는 Y 또는 N 만 (MySQL 8.0.16 이상에서 실제로 검사된다) */
    constraint chk_comment_del check (del_flag in ('Y','N'))
-- 표 만들기 끝. 한글이 깨지지 않도록 utf8mb4 로 지정한다
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_unicode_ci comment='자유게시판 댓글';
/* ==============================================================================
   2. 댓글 추천 (누가 어느 댓글을 추천했는가)
   ============================================================================== */
create table board_comment_like (
    -- 댓글번호 칸 — 정수 로 저장한다. 비워 둘 수 없다
    c_idx      int          not null  comment '추천한 댓글번호',
    member_id  varchar(50)  not null  comment '추천한 회원 아이디',
    reg_date   datetime     not null default current_timestamp  comment '추천일시',
    /* [핵심] (댓글, 회원) 을 묶어 기본키로 만든다.
       같은 사람이 같은 댓글을 두 번 추천하면 DB 가 중복으로 막아준다.
       "코드로 검사" 가 아니라 "DB 구조로 불가능하게" 만드는 것이 안전하다. */
    primary key (c_idx, member_id),
    /* 회원이 자기가 누른 추천을 모아 볼 수 있도록 */
    key idx_like_member (member_id),
    constraint fk_like_comment foreign key (c_idx)
        -- 어느 표의 어느 칸과 연결되는지, 원본이 지워지면 어떻게 할지
        references board_comment (c_idx) on delete cascade on update cascade
-- 표 만들기 끝. 한글이 깨지지 않도록 utf8mb4 로 지정한다
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_unicode_ci comment='댓글 추천';
/* ==============================================================================
   3. 샘플 댓글 (무한 대댓글 구조를 눈으로 확인하기 위한 데이터)
   [주의] b_idx 값은 02_sample_data.sql 로 만들어진 글 번호를 가리킨다.
          글을 지웠다면 존재하는 번호로 바꿔야 외래키 제약에 걸리지 않는다.
   ============================================================================== */
/* 1번 글에 최상위 댓글 2개 */
insert into board_comment (b_idx, parent_idx, c_id, c_name, c_content) values
-- 넣을 값 한 줄 (컬럼 순서대로)
(1, null, 'user01', '홍길동', '차량 상태가 정말 깨끗했습니다. 다음에도 이용할게요!'),
(1, null, 'kim',    '김영희', '보험 옵션은 꼭 넣으시는 걸 추천합니다.');
/* 위 1번 댓글에 대한 답글 (2단) */
insert into board_comment (b_idx, parent_idx, c_id, c_name, c_content) values
-- 넣을 값 한 줄 (컬럼 순서대로)
(1, 1, 'kim', '김영희', '저도 같은 차량 이용했는데 만족했어요.');
/* 그 답글에 대한 또 답글 (3단) - 깊이 제한이 없다는 것을 보여준다 */
insert into board_comment (b_idx, parent_idx, c_id, c_name, c_content) values
-- 넣을 값 한 줄 (컬럼 순서대로)
(1, 3, 'lee', '이철수', '어떤 차량이었는지 알 수 있을까요?');
/* 4단 */
insert into board_comment (b_idx, parent_idx, c_id, c_name, c_content) values
-- 넣을 값 한 줄 (컬럼 순서대로)
(1, 4, 'kim', '김영희', '아반떼였습니다. 연비가 좋았어요.');
/* 샘플 추천 : 1번 댓글을 kim, lee 두 명이 추천 -> 추천 수 2 */
insert into board_comment_like (c_idx, member_id) values
-- 넣을 값 한 줄 (컬럼 순서대로)
(1, 'kim'),
(1, 'lee'),
(2, 'user01');
-- 고칠 컬럼과 새 값
set sql_safe_updates = 1;
/* ==============================================================================
   확인용 조회
   ============================================================================== */
/* 댓글이 트리 구조로 잘 들어갔는지 (부모 -> 자식 순서로 보인다) */
select c.c_idx, c.parent_idx, c.c_name, c.c_content,
       (select count(*) from board_comment_like l where l.c_idx = c.c_idx) as 추천수
  from board_comment c
 -- 어느 줄에 적용할지 고르는 조건
 where c.b_idx = 1
 -- 결과를 정렬하는 기준
 order by c.c_idx;
/* 글별 댓글 개수 */
select b_idx, count(*) as 댓글수 from board_comment group by b_idx;