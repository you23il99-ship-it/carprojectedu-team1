```jsp
<%@ page import="Vo.MemberVO"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>

<%
request.setCharacterEncoding("UTF-8");

String contextPath = request.getContextPath();

/*
 * nowPage, nowBlock 을 받는 이유
 *
 * list.jsp 에서 페이지 번호를 보다가 글쓰기 화면으로 넘어왔다.
 * 글 작성 후 목록 버튼을 누르면 원래 보고 있던 페이지로 돌아가기 위해
 * nowPage, nowBlock 값을 받아 둔다.
 */
String nowPage = (String) request.getAttribute("nowPage");
String nowBlock = (String) request.getAttribute("nowBlock");

// 로그인한 회원 정보
MemberVO membervo = (MemberVO) request.getAttribute("membervo");

String email = membervo.getEmail();
String name = membervo.getName();
String id = membervo.getId();
%>

<%--
=============================================================================
 board/write.jsp - 자유게시판 글쓰기 화면

 요청 흐름

 list.jsp
     ↓
 /Board/write.bo
     ↓
 BoardController
     ↓
 로그인한 회원 정보(membervo)를 request에 저장
     ↓
 write.jsp

 등록
     ↓
 JavaScript
     ↓
 /Board/writePro.bo
     ↓
 BoardController
     ↓
 BoardService
     ↓
 DAO
     ↓
 DB

 목록
     ↓
 원래 보고 있던 nowPage, nowBlock을 가지고
 /Board/list.bo 로 이동
=============================================================================
--%>


<div class="board-container">

	<h2 class="section-title">자유게시판</h2>


	<form id="writeForm" onsubmit="return false;">

		<%-- 작성자 / 아이디 : 로그인 정보이므로 수정할 수 없다 --%>

		<div class="grid-2">

			<div class="form-group">

				<label class="form-label" for="writer"> 작성자 </label> <input
					class="form-control" type="text" id="writer" name="writer"
					value="<%=util.HtmlUtil.escape(name)%>" readonly>

			</div>


			<div class="form-group">

				<label class="form-label" for="writer_id"> 아이디 </label> <input
					class="form-control" type="text" id="writer_id" name="writer_id"
					value="<%=util.HtmlUtil.escape(id)%>" readonly>

			</div>

		</div>


		<div class="form-group">

			<label class="form-label" for="email"> 메일주소 </label> <input
				class="form-control" type="email" id="email" name="email"
				value="<%=util.HtmlUtil.escape(email)%>" readonly>

		</div>


		<div class="form-group">

			<label class="form-label" for="title"> 제목 <span
				class="required">*</span>
			</label> <input class="form-control" type="text" id="title" name="title"
				maxlength="200" placeholder="제목을 입력하세요">

		</div>


		<div class="form-group">

			<label class="form-label" for="content"> 내용 </label>

			<textarea class="form-control" id="content" name="content"
				placeholder="내용을 입력하세요"></textarea>

		</div>


		<div class="form-group">

			<label class="form-label" for="pass"> 비밀번호 <span
				class="required">*</span>
			</label> <input class="form-control" type="password" id="pass" name="pass"
				placeholder="글 수정·삭제에 사용됩니다">

			<p class="form-hint">• 나중에 이 글을 수정하거나 삭제할 때 필요합니다. 꼭 기억해 주세요.</p>

		</div>

	</form>


	<%-- 버튼 --%>

	<div class="flex flex-wrap gap-2 justify-between mt-6">

		<button type="button" id="registration1" class="btn btn-primary">
			등록</button>

		<button type="button" id="list" class="btn btn-ghost">목록</button>

	</div>


	<%-- 등록 결과 메시지 --%>

	<p id="resultInsert" class="mt-4 fw-bold"></p>

</div>


<script src="https://code.jquery.com/jquery-latest.min.js"></script>

<script>

	var ctx = "<%=contextPath%>";


	$(function () {


		/*
		 * =========================================================
		 * [목록] 버튼
		 * =========================================================
		 *
		 * 현재 글쓰기 화면에 들어오기 전의 페이지로 돌아간다.
		 */

		$("#list").on("click", function(event) {

			event.preventDefault();

			location.href =
				ctx
				+ "/Board/list.bo"
				+ "?nowPage=<%=nowPage%>"
				+ "&nowBlock=<%=nowBlock%>";

		});


		/*
		 * =========================================================
		 * [등록] 버튼
		 * =========================================================
		 *
		 * 입력값을 가져온 후
		 *
		 * /Board/writePro.bo
		 *
		 * 로 전송한다.
		 */

		$("#registration1").on("click", function(event) {

			event.preventDefault();


			/*
			 * -----------------------------------------------------
			 * 1. form 찾기
			 * -----------------------------------------------------
			 */

			var form = document.getElementById("writeForm");


			/*
			 * -----------------------------------------------------
			 * 2. 입력값 가져오기
			 * -----------------------------------------------------
			 */

			var writer =
				form.querySelector("input[name=writer]").value;

			var id =
				form.querySelector("input[name=writer_id]").value;

			var email =
				form.querySelector("input[name=email]").value;

			var title =
				form.querySelector("input[name=title]").value;

			var content =
				form.querySelector("textarea[name=content]").value;

			var pass =
				form.querySelector("input[name=pass]").value;


			/*
			 * -----------------------------------------------------
			 * 3. 제목 검사
			 * -----------------------------------------------------
			 */

			if(title.trim() === "") {

				CarApp.setText(
					"resultInsert",
					"글 제목을 입력해주세요.",
					"red"
				);

				return;
			}


			/*
			 * -----------------------------------------------------
			 * 4. 비밀번호 검사
			 * -----------------------------------------------------
			 */

			if(pass.trim() === "") {

				CarApp.setText(
					"resultInsert",
					"글 비밀번호를 입력해주세요.",
					"red"
				);

				return;
			}


			/*
			 * -----------------------------------------------------
			 * 5. 서버에 글 등록 요청
			 * -----------------------------------------------------
			 *
			 * BoardController에서 받는 이름
			 *
			 * w = writer
			 * i = id
			 * e = email
			 * t = title
			 * c = content
			 * p = pass
			 */

			CarApp.postForm(
				ctx + "/Board/writePro.bo",
				{
					w : writer,
					i : id,
					e : email,
					t : title,
					c : content,
					p : pass
				}
			)
			.then(function(responseData) {

    /*
     * 서버에서
     *
     * 성공 → "1"
     * 실패 → "0"
     *
     * 을 보내준다.
     */
    if(responseData === "1") {

        CarApp.setText(
            "resultInsert",
            "글작성 완료!",
            "green"
        );

        /*
         * 글 작성 성공 후 목록으로 이동할지 확인
         */
        if(
            window.confirm(
                "추가한 글을 조회해서 보기 위해 목록페이지로 이동하시겠습니까?"
            )
        ) {
            location.href =
                ctx + "/Board/list.bo";
        }

    }
    else {

        CarApp.setText(
            "resultInsert",
            "글작성 실패",
            "red"
        );
    }

})
.catch(function(err) {

    CarApp.setText(
        "resultInsert",
        "글작성 실패 : " + err.message,
        "red"
    );

});
			
		});

	});

</script>

