# 부루미 공유 확장 (iPhone, tips 350 + 182)

다른 앱의 공유 버튼 → "부루미"를 누르면 이 작은 확장이 사진·영상·파일·글을
앱 그룹 폴더(`group.app.burumy.burumy`)에 복사하고 부루미를 엽니다. 부루미가
"어디로 보낼까요" 화면을 띄웁니다. 확장에는 암호 키가 없고 서버와 통신하지 않습니다.

Mac + Xcode에서 한 번만 할 일 (Apple 개발자 등록 후):
1. Runner.xcworkspace 열기 → File > New > Target > Share Extension, 이름 `ShareExtension`,
   번들 ID `app.burumy.burumy.ShareExtension`. Xcode가 만든 파일은 지우고 이 폴더의
   `ShareViewController.swift`, `Info.plist`, `ShareExtension.entitlements`를 씁니다.
2. Runner 타깃과 ShareExtension 타깃 둘 다 Signing & Capabilities > App Groups에
   `group.app.burumy.burumy` 추가 (Runner는 `Runner/Runner.entitlements`가 생김).
3. Runner의 Info.plist URL Types에 스킴 `burumy` 추가 (확장이 앱을 열 때 사용).
4. 확장 타깃의 최소 iOS = Runner와 같게.
5. 실기기에서 시험: 사진 앱 → 공유 → 부루미 → 대화 고르기 → 보내기 → 진행 막대 → 완료.
