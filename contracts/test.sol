// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Certificate {
    // กำหนดโครงสร้างข้อมูลของนักศึกษา
    struct Student {
        string name; // ชื่อ-นามสกุล
        uint studentID; // รหัสนักศึกษา
        string faculty; // คณะ
        string department; // ภาควิชา
        bool certificateIssued; // สถานะใบประกาศนียบัตร
    }

    // เก็บข้อมูลของนักศึกษาโดยใช้ที่อยู่ (address) เป็น key
    mapping(address => Student) public students;

    // Event สำหรับแสดงข้อมูลใบประกาศนียบัตรที่ออกให้แก่นักศึกษา
    event CertificateIssued(address indexed studentAddress, string name, uint studentID, string faculty, string department);

    // ฟังก์ชันสำหรับออกใบประกาศนียบัตร
    function issueCertificate(string memory name, uint studentID, string memory faculty, string memory department) public {
        // ตรวจสอบว่าใบประกาศนียบัตรยังไม่ถูกออกให้แก่นักศึกษา
        require(students[msg.sender].certificateIssued == false, "Certificate already issued.");

        // บันทึกข้อมูลนักศึกษาลงใน mapping
        students[msg.sender] = Student(name, studentID, faculty, department, true);

        // ส่ง event ให้ทราบว่าใบประกาศนียบัตรถูกออก
        emit CertificateIssued(msg.sender, name, studentID, faculty, department);
    }
}
