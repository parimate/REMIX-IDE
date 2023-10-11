// SPDX-License-Identifier: GPL-3.0
// เลขที่ใบอนุญาต: GPL-3.0

pragma solidity >=0.8.0 <0.10.0; // เลือกเวอร์ชันของ Solidity ที่อยู่ในช่วง 0.8.0 ถึง 0.9.0

contract Upload {

    // สร้างโครงสร้าง Access ที่ใช้ในการเก็บข้อมูลการเข้าถึงของผู้ใช้
    struct Access {
        address user; // ที่อยู่ของผู้ใช้
        bool access; // สถานะการเข้าถึง (true หมายถึงมีสิทธิ์เข้าถึง, false หมายถึงไม่มีสิทธิ์เข้าถึง)
        string fullName; // ข้อมูลชื่อ-นามสกุล
        string studentId; // ข้อมูลรหัสนักศึกษา
    }  

    mapping(address => string[]) value; // แม็พของรายการ URL ที่ผู้ใช้เพิ่มเข้าไป
    mapping(address => mapping(address => bool)) ownership; // แม็พของสิทธิ์การเปิดเผยข้อมูลระหว่างผู้ใช้
    mapping(address => Access[]) accessList; // แม็พของรายการการเข้าถึงข้อมูลระหว่างผู้ใช้
    mapping(address => mapping(address => bool)) previousData; // แม็พของสถานะก่อนหน้าของข้อมูลระหว่างผู้ใช้

    // ฟังก์ชันเพิ่ม URL ของผู้ใช้
    function add(address _user, string memory url, string memory _fullName, string memory _studentId) external {
        value[_user].push(url);
        
        // เพิ่มรายการการเข้าถึงข้อมูลใหม่เข้าไปใน accessList พร้อมกับข้อมูล full-name และ student-id
        accessList[_user].push(Access(msg.sender, true, _fullName, _studentId));
    }

    // ฟังก์ชันอนุญาตให้ผู้ใช้รายอื่นเข้าถึงข้อมูล
    function allow(address user) external {
        ownership[msg.sender][user] = true; // ตั้งค่าสิทธิ์ให้กับผู้ใช้ที่ระบุเพื่อเปิดเผยข้อมูล
        if (previousData[msg.sender][user]) {
            // ถ้ามีการเข้าถึงข้อมูลก่อนหน้านี้ ให้อัปเดตสถานะการเข้าถึงให้เป็น true
            for (uint256 i = 0; i < accessList[msg.sender].length; i++) {
                if (accessList[msg.sender][i].user == user) {
                    accessList[msg.sender][i].access = true;
                }
            }
        } else {
            // ถ้าไม่เคยมีการเข้าถึงข้อมูลก่อนหน้านี้ ให้เพิ่มรายการการเข้าถึงใหม่และตั้งค่าสถานะก่อนหน้าเป็น true
            accessList[msg.sender].push(Access(user, true, "", ""));
            previousData[msg.sender][user] = true;
        }
    }

    // ฟังก์ชันไม่อนุญาตให้ผู้ใช้รายอื่นเข้าถึงข้อมูล
    function disallow(address user) external {
        ownership[msg.sender][user] = false; // ยกเลิกสิทธิ์การเปิดเผยข้อมูลของผู้ใช้ที่ระบุ
        for (uint256 i = 0; i < accessList[msg.sender].length; i++) {
            // อัปเดตสถานะการเข้าถึงเป็น false สำหรับผู้ใช้ที่ระบุ
            if (accessList[msg.sender][i].user == user) {
                accessList[msg.sender][i].access = false;
            }
        }
    }

    // ฟังก์ชันแสดงรายการ URL ของผู้ใช้
    function display(address _user) external view returns (string[] memory) {
        // ตรวจสอบว่าผู้ใช้เป็นเจ้าของหรือมีสิทธิ์ในการเข้าถึงข้อมูล หากไม่ใช่จะโยนข้อผิดพลาด
        require(_user == msg.sender || ownership[_user][msg.sender], "You don't have access");
        return value[_user];
    }

    // ฟังก์ชันแสดงรายการการเข้าถึงข้อมูลของผู้ใช้เอง
    function shareAccess() public view returns (Access[] memory) {
        return accessList[msg.sender];
    }
}
