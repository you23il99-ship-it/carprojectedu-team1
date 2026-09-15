/* ============================================================================
   join.js  -  회원가입 화면(members/join.jsp) 입력 검사

   하는 일
     1. 입력칸을 벗어날 때(blur) 규칙에 맞는지 검사해서 빨강/파랑 안내 문구를 보여준다
     2. 아이디는 fetch 로 서버에 중복 확인을 요청한다
     3. 회원가입하기 버튼을 누르면 check() 가 전체를 다시 검사하고, 모두 통과하면 form 을 전송한다

   모든 checkXxx() 함수의 약속
     통과 : 파란 글씨 안내 + true 반환
     실패 : 빨간 글씨 안내 + false 반환

   이 파일은 join.jsp 맨 아래에서 불러온다 (입력칸이 먼저 만들어져 있어야 이벤트를 연결할 수 있다)
   ============================================================================ */


/* ----------------------------------------------------------------------------
   0. 안내 문구 표시 함수
   ---------------------------------------------------------------------------- */

// 안내 자리(id)에 안내 문구(text)를 글자 색(color)으로 표시한다
// 사용 예) showMsg("idInput", "사용할 수 있는 ID입니다.", "blue");
function showMsg(id, text, color) {

    // 안내 자리 찾기  예) <p id="idInput">
    const box = document.getElementById(id);

    // 안내 자리에 안내 문구를 넣는다
    box.textContent = text;

    // 안내 문구의 글자 색을 바꾼다 (빨강 = 잘못 입력, 파랑 = 올바르게 입력)
    box.style.color = color;
}


/* ----------------------------------------------------------------------------
   1. 약관 동의
   ---------------------------------------------------------------------------- */

// 약관 동의 체크박스가 체크되어 있는지 검사한다
function checkAgree() {

    // 약관 동의 체크박스(<input type="checkbox" id="agree">) 찾기
    const agree = document.getElementById("agree");

    // 체크되어 있으면 파란 글씨로 안내하고 true 반환
    if (agree.checked) {
        showMsg("agreeInput", "약관동의 완료!", "blue");
        return true;
    }

    // 체크되어 있지 않으면 빨간 글씨로 안내하고 false 반환
    showMsg("agreeInput", "약관에 동의해 주세요!", "red");
    return false;
}

// 약관 동의 체크박스를 클릭할 때마다 checkAgree 함수를 실행하도록 연결한다
document.getElementById("agree").addEventListener("click", checkAgree);


/* ----------------------------------------------------------------------------
   2. 아이디  (형식 검사 + 서버 중복 확인)
   ---------------------------------------------------------------------------- */

// 아이디가 규칙(영문, 숫자, _, - 로 3~20글자)에 맞는지 검사한다
function checkId() {

    // 아이디 입력칸(<input id="id">)에 입력한 값 얻기
    const id = document.getElementById("id").value;

    // 규칙에 맞으면 true 반환 (파란 안내 문구는 서버 중복 확인 결과를 받은 뒤에 보여준다)
    if (/^[A-Za-z0-9_\-]{3,20}$/.test(id)) {
        return true;
    }

    // 규칙에 맞지 않으면 빨간 글씨로 안내하고 false 반환
    showMsg("idInput", "영문, 숫자, _, - 로 3~20글자 작성해 주세요!", "red");
    return false;
}

// 서버에 아이디 중복 확인을 요청한다
//   고객(웹브라우저) --- POST id=hong ---> 사장(MemberController) /member/joinIdCheck.me
//   고객(웹브라우저) <-- "usable"(사용 가능) 또는 "not_usable"(중복) ---
// async : 이 함수 안에서 await(서버 응답 기다리기)를 쓰겠다는 표시
async function checkIdDuplicate() {

    // 요청 주소 만들기  예) "/CarProject" + "/member/joinIdCheck.me"  (CONTEXT_PATH 는 join.jsp 가 알려준다)
    const url = window.CONTEXT_PATH + "/member/joinIdCheck.me";

    // 서버로 보낼 값을 담을 상자 만들기 (서블릿이 request.getParameter() 로 꺼낼 수 있는 형식)
    const params = new URLSearchParams();

    // 아이디 입력칸의 값을 "id" 라는 이름으로 상자에 넣는다  ->  id=hong
    params.append("id", document.getElementById("id").value);

    try {

        // 서버에 POST 방식으로 요청을 보내고, 응답이 올 때까지 기다렸다가(await) response 에 저장
        const response = await fetch(url, { method: "POST", body: params });

        // 응답이 정상(200번대)이 아니면 (404 주소 없음, 500 서버 오류 등) 오류를 발생시켜 catch 로 보낸다
        if (!response.ok) {
            throw new Error("서버 오류 " + response.status);
        }

        // 서버가 보낸 응답 글자를 읽고(await), 앞뒤 공백을 지워 result 에 저장  ->  "usable" 또는 "not_usable"
        const result = (await response.text()).trim();

        // "usable" 이면 사용할 수 있는 아이디이므로 파란 글씨로 안내
        if (result === "usable") {
            showMsg("idInput", "사용할 수 있는 ID입니다.", "blue");

        // 그 외("not_usable")면 이미 가입된 아이디이므로 빨간 글씨로 안내
        } else {
            showMsg("idInput", "이미 사용중인 ID입니다.", "red");
        }

    // 서버가 꺼졌거나, 주소가 틀렸거나, 인터넷이 끊겨 요청에 실패한 경우
    } catch (error) {

        // 빨간 글씨로 오류를 안내한다
        showMsg("idInput", "아이디 확인 중 오류가 발생했습니다.", "red");

        // 개발자가 원인을 볼 수 있도록 브라우저 F12 > Console 탭에 오류 내용을 출력한다
        console.error(error);
    }
}

// 아이디 입력칸에서 커서가 벗어나면(blur) 형식을 검사하고, 통과하면 서버에 중복 확인을 요청한다
document.getElementById("id").addEventListener("blur", function () {
    if (checkId()) {
        checkIdDuplicate();
    }
});


/* ----------------------------------------------------------------------------
   3. 비밀번호  (영문, 숫자, _, - 로 4~20글자)
   ---------------------------------------------------------------------------- */

function checkPass() {

    // 비밀번호 입력칸(<input type="password" id="pass">)에 입력한 값 얻기
    const pass = document.getElementById("pass").value;

    // 규칙에 맞으면 파란 글씨로 안내하고 true 반환
    if (/^[A-Za-z0-9_\-]{4,20}$/.test(pass)) {
        showMsg("passInput", "올바르게 입력되었습니다.", "blue");
        return true;
    }

    // 규칙에 맞지 않으면 빨간 글씨로 안내하고 false 반환
    showMsg("passInput", "영문, 숫자, _, - 로 4~20글자 작성해 주세요!", "red");
    return false;
}

// 비밀번호 입력칸에서 커서가 벗어나면(blur) checkPass 함수를 실행하도록 연결한다
document.getElementById("pass").addEventListener("blur", checkPass);


/* ----------------------------------------------------------------------------
   4. 이름  (한글 2~6글자)
   ---------------------------------------------------------------------------- */

function checkName() {

    // 이름 입력칸(<input id="name">)에 입력한 값 얻기
    const name = document.getElementById("name").value;

    // 한글 2~6글자이면 파란 글씨로 안내하고 true 반환  ([가-힣] = 한글 한 글자)
    if (/^[가-힣]{2,6}$/.test(name)) {
        showMsg("nameInput", "이름입력완료!", "blue");
        return true;
    }

    // 규칙에 맞지 않으면 빨간 글씨로 안내하고 false 반환
    showMsg("nameInput", "이름을 한글 2~6자로 작성해 주세요.", "red");
    return false;
}

// 이름 입력칸에서 커서가 벗어나면(blur) checkName 함수를 실행하도록 연결한다
document.getElementById("name").addEventListener("blur", checkName);


/* ----------------------------------------------------------------------------
   5. 나이  (비어 있지 않으면 통과)
   ---------------------------------------------------------------------------- */

function checkAge() {

    // 나이 입력칸(<input id="age">)에 입력한 값을 얻고, 앞뒤 공백을 지운다
    const age = document.getElementById("age").value.trim();

    // 입력했으면 파란 글씨로 안내하고 true 반환
    if (age !== "") {
        showMsg("ageInput", "나이입력완료!", "blue");
        return true;
    }

    // 비어 있으면 빨간 글씨로 안내하고 false 반환
    showMsg("ageInput", "나이를 입력해주세요.", "red");
    return false;
}

// 나이 입력칸에서 커서가 벗어나면(blur) checkAge 함수를 실행하도록 연결한다
document.getElementById("age").addEventListener("blur", checkAge);


/* ----------------------------------------------------------------------------
   6. 주소  (address1 ~ address5 다섯 칸이 모두 채워져야 통과)
   ---------------------------------------------------------------------------- */

// name 속성이 address1 ~ address5 인 주소 입력칸 5개를 한 번에 찾아 저장한다
const addressInputs = document.querySelectorAll(
    "[name='address1'], [name='address2'], [name='address3'], [name='address4'], [name='address5']"
);

function checkAddress() {

    // 주소 입력칸 5개를 하나씩 확인한다 (i = 0, 1, 2, 3, 4)
    for (let i = 0; i < addressInputs.length; i++) {

        // 한 칸이라도 비어 있으면 빨간 글씨로 안내하고 false 반환
        if (addressInputs[i].value.trim() === "") {
            showMsg("addressInput", "주소를 모두 작성하여주세요.", "red");
            return false;
        }
    }

    // 5칸 모두 채워져 있으면 파란 글씨로 안내하고 true 반환
    showMsg("addressInput", "올바르게 입력되었습니다.", "blue");
    return true;
}

// 주소 입력칸 5개 각각에서 커서가 벗어나면(blur) checkAddress 함수를 실행하도록 연결한다
for (let i = 0; i < addressInputs.length; i++) {
    addressInputs[i].addEventListener("blur", checkAddress);
}


/* ----------------------------------------------------------------------------
   7. 성별  (남성, 여성 중 하나를 선택해야 통과)
   ---------------------------------------------------------------------------- */

function checkGender() {

    // class="gender" 인 라디오 버튼 중 선택된(:checked) 것 찾기. 없으면 null
    const checked = document.querySelector(".gender:checked");

    // 선택된 것이 있으면 파란 글씨로 안내하고 true 반환
    if (checked) {
        showMsg("genderInput", "성별체크완료!", "blue");
        return true;
    }

    // 선택된 것이 없으면 빨간 글씨로 안내하고 false 반환
    showMsg("genderInput", "성별을 체크 해주세요.", "red");
    return false;
}

// 성별 라디오 버튼(남성, 여성)을 모두 찾는다
const genderButtons = document.querySelectorAll(".gender");

// 성별 라디오 버튼 각각을 클릭하면 checkGender 함수를 실행하도록 연결한다
for (let i = 0; i < genderButtons.length; i++) {
    genderButtons[i].addEventListener("click", checkGender);
}


/* ----------------------------------------------------------------------------
   8. 이메일  (예: abcde@naver.com)
   ---------------------------------------------------------------------------- */

function checkEmail() {

    // 이메일 입력칸(<input type="email" id="email">)에 입력한 값 얻기
    const email = document.getElementById("email").value;

    // 이메일 규칙 : 영문·숫자 5~12자 + @ + 소문자 2~10자 + . + 소문자 2~3자 (+ .kr 같은 끝자리 허용)
    if (/^\w{5,12}@[a-z]{2,10}[\.][a-z]{2,3}[\.]?[a-z]{0,2}$/.test(email)) {
        showMsg("emailInput", "올바르게 입력되었습니다.", "blue");
        return true;
    }

    // 규칙에 맞지 않으면 빨간 글씨로 안내하고 false 반환
    showMsg("emailInput", "이메일 형식이 올바르지 않습니다.", "red");
    return false;
}

// 이메일 입력칸에서 커서가 벗어나면(blur) checkEmail 함수를 실행하도록 연결한다
document.getElementById("email").addEventListener("blur", checkEmail);


/* ----------------------------------------------------------------------------
   9. 연락처  (0 으로 시작하는 숫자 9~11자리, - 없이)
   ---------------------------------------------------------------------------- */

function checkTel() {

    // 연락처 입력칸(<input type="tel" id="tel">)에 입력한 값 얻기
    const tel = document.getElementById("tel").value;

    // 0 으로 시작하고 뒤에 숫자 8~10개가 오면 통과  예) 0515551234
    if (/^0[0-9]{8,10}$/.test(tel)) {
        showMsg("telInput", "올바르게 입력되었습니다.", "blue");
        return true;
    }

    // 규칙에 맞지 않으면 빨간 글씨로 안내하고 false 반환
    showMsg("telInput", "전화번호 형식이 올바르지 않습니다.", "red");
    return false;
}

// 연락처 입력칸에서 커서가 벗어나면(blur) checkTel 함수를 실행하도록 연결한다
document.getElementById("tel").addEventListener("blur", checkTel);


/* ----------------------------------------------------------------------------
   10. 핸드폰번호  (010, 011, 017, 019 + 숫자 7~8자리, - 없이)
   ---------------------------------------------------------------------------- */

function checkHp() {

    // 핸드폰번호 입력칸(<input id="hp">)에 입력한 값 얻기
    const hp = document.getElementById("hp").value;

    // 01 + [0,1,7,9 중 하나] + 숫자 7~8개이면 통과  예) 01012345678
    if (/^01[0179][0-9]{7,8}$/.test(hp)) {
        showMsg("hpInput", "올바르게 입력되었습니다.", "blue");
        return true;
    }

    // 규칙에 맞지 않으면 빨간 글씨로 안내하고 false 반환
    showMsg("hpInput", "휴대폰번호 형식이 올바르지 않습니다.", "red");
    return false;
}

// 핸드폰번호 입력칸에서 커서가 벗어나면(blur) checkHp 함수를 실행하도록 연결한다
document.getElementById("hp").addEventListener("blur", checkHp);


/* ----------------------------------------------------------------------------
   11. 회원가입하기 버튼  -  join.jsp 의 onclick="check(); return false;" 가 부른다

       1~10 번 검사를 순서대로 실행한다.
       하나라도 실패(false)하면 그 입력칸으로 커서를 옮기고 멈춘다.
       모두 통과(true)하면 form 을 사장(MemberController)의 /member/joinPro.me 로 전송한다.
   ---------------------------------------------------------------------------- */

function check() {

    // 1. 약관 동의 검사. 실패하면 함수를 끝낸다  (! = 반대로. 실패(false)이면 true 가 되어 { } 안을 실행)
    if (!checkAgree()) { return; }

    // 2. 아이디 검사. 실패하면 아이디 입력칸으로 커서를 옮기고 함수를 끝낸다
    if (!checkId())    { document.getElementById("id").focus();    return; }

    // 3. 비밀번호 검사. 실패하면 비밀번호 입력칸으로 커서를 옮기고 함수를 끝낸다
    if (!checkPass())  { document.getElementById("pass").focus();  return; }

    // 4. 이름 검사. 실패하면 이름 입력칸으로 커서를 옮기고 함수를 끝낸다
    if (!checkName())  { document.getElementById("name").focus();  return; }

    // 5. 나이 검사. 실패하면 나이 입력칸으로 커서를 옮기고 함수를 끝낸다
    if (!checkAge())   { document.getElementById("age").focus();   return; }

    // 6. 주소 검사. 실패하면 함수를 끝낸다
    if (!checkAddress()) { return; }

    // 7. 성별 검사. 실패하면 함수를 끝낸다
    if (!checkGender())  { return; }

    // 8. 이메일 검사. 실패하면 이메일 입력칸으로 커서를 옮기고 함수를 끝낸다
    if (!checkEmail()) { document.getElementById("email").focus(); return; }

    // 9. 연락처 검사. 실패하면 연락처 입력칸으로 커서를 옮기고 함수를 끝낸다
    if (!checkTel())   { document.getElementById("tel").focus();   return; }

    // 10. 핸드폰번호 검사. 실패하면 핸드폰번호 입력칸으로 커서를 옮기고 함수를 끝낸다
    if (!checkHp())    { document.getElementById("hp").focus();    return; }

    // 11. 모두 통과했으면 join.jsp 의 form 을 찾아 사장(MemberController)의 /member/joinPro.me 로 전송한다
    document.querySelector("form[action$='/member/joinPro.me']").submit();
}
