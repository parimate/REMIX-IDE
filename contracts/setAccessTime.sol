// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Certificate {
    struct Student {
        //address studentAddress;
        string studentName; // ชื่อ-นามสกุลของนักศึกษา
        string studentId; // รหัสนักศึกษา
        string faculty; // คณะ
        string department; // ภาควิชา
        uint256 accessTime; // เวลาที่อนุญาตให้เข้าดูข้อมูล
        // bool revokedStatus;   // สถานะเพิกถอนใบประกาศนียบัตร
    }

    struct Admin {
        string name; // ชื่อ-นามสกุล
        string adminId; // รหัสประจำตัว
        string position; // ตำแหน่งหน้าที่
    }

    Student[] public StudentCertificate;

    mapping(address => bool) public authorizedIssuers; // รายชื่อผู้ที่มีสิทธิ์ในการออกใบประกาศนียบัตร
    mapping(address => bool) private authorizedViewers; // รายชื่อผู้ที่มีสิทธิ์ในการดูข้อมูลใบประกาศนียบัตร
    mapping(address => bool) private authorizedStudent;
    mapping(address => Student) private students; // ข้อมูลใบประกาศนียบัตรของนักศึกษา
    mapping(address => Admin) private admins; // ข้อมูลใบผู้ที่มีสิทธิ์ในการออกใบประกาศนียบัตร
    mapping(address => uint256) private viewerAccessTimes; // เก็บเวลาการเข้าถึงของผู้เข้าชม

    constructor() {
        authorizedIssuers[msg.sender] = true; // Contract creator is the initial admin
    }

    modifier onlyAuthorizedIssuer() {
        require(authorizedIssuers[msg.sender], "Only authorized issuers can call this function");
        _;
    }

    modifier onlyAuthorizedViewer() {
        require(
            authorizedViewers[msg.sender], "Only authorized viewers can call this function");
        _;
    }

    modifier onlyStudent() {
        require(authorizedStudent[msg.sender],"Only student can call this function");
        _;
    }

    //----------------------------------------------------------------------------------------------//

    // เพิ่มรายชื่อผู้มีสิทธิ์ออกใบประกาศนียบัตร
    function addAdmin(
        address _authorizedIssuers,
        string memory name,
        string memory adminId,
        string memory position
    ) external onlyAuthorizedIssuer {
        authorizedIssuers[_authorizedIssuers] = true;
        Admin storage admin = admins[_authorizedIssuers];
        admin.name = name;
        admin.adminId = adminId;
        admin.position = position;
    }

    // ลบรายชื่อออกจากผู้มีสิทธิ์ออกใบประกาศนียบัตร
    function removeAdmin(address _authorizedIssuers) external onlyAuthorizedIssuer{
        authorizedIssuers[_authorizedIssuers] = false;
    }

    function getAdmin() public view returns (
            string memory name,
            string memory id,
            string memory position
        )
    {
        require(authorizedIssuers[msg.sender],"You are not authorized to run this function.");
        Admin storage admin = admins[msg.sender];
        return (admin.name, admin.adminId, admin.position);
    }

    //----------------------------------------------------------------------------------------------//

    //เพิ่มผู้เข้าชมที่ได้รับสิทธิ์และกำหนดเวลาในการดูข้อมูลใบประกาศนียบัตร
    function addViewer(address viewers, uint256 timestamp)
        external
        onlyStudent
    {
        Student storage student = students[msg.sender];
        student.accessTime = block.timestamp + timestamp;
        authorizedViewers[viewers] = true;
    }

    // // ลบผู้เข้าชมที่ได้รับสิทธิ์ในการดูข้อมูลใบประกาศนียบัตรออกจากรายชื่อผู้มีสิทธิ์
    // function removeViewer(address viewer) external onlyStudent {
    //     authorizedViewers[viewer] = false;
    // }

    //----------------------------------------------------------------------------------------------//

    // ออกใบประกาศนียบัตรโดยผู้ออกใบประกาศนียบัตร
    function issueCertificate(
        address studentAddress,
        string memory studentName,
        string memory studentId,
        string memory faculty,
        string memory department
    ) external onlyAuthorizedIssuer {
        authorizedStudent[studentAddress] = true; // เพิ่มที่อยู่ของนักเรียนให้กับนักเรียนที่ได้รับอนุญาต
        Student storage student = students[studentAddress];
        student.studentName = studentName;
        student.studentId = studentId;
        student.faculty = faculty;
        student.department = department;

        StudentCertificate.push(
            Student(studentName, studentId, faculty, department, 0)
        );
    }

    function viewStudent() public view returns (Student[] memory) {
        uint256 numCertificates = StudentCertificate.length;
        Student[] memory certificates = new Student[](numCertificates);

        for (uint256 i = 0; i < numCertificates; i++) {
            certificates[i] = StudentCertificate[i];
        }

        return certificates;
    }

    //  // กำหนดเวลาในการดูข้อมูลใบประกาศนียบัตร
    // function setAccessTime(uint256 timestamp) external onlyAuthorizedViewer {
    //     Student storage student = students[msg.sender];
    //     require(student.accessTime == 0, "Access time already set");
    //     require(timestamp > block.timestamp, "Access time should be in the future");
    //     student.accessTime = timestamp;
    // }

    // ดึงข้อมูลใบประกาศนียบัตรของนักศึกษา
    function getCertificate() public view returns (
            string memory studentName,
            string memory studentId,
            string memory faculty,
            string memory department
        )
    {
        require(
            authorizedStudent[msg.sender] || authorizedIssuers[msg.sender],
            "You are not authorized to run this function."
        );
        Student storage student = students[msg.sender];
        return (student.studentName, student.studentId, student.faculty, student.department);
    }

    // ดึงข้อมูลใบประกาศนียบัตรของนักศึกษาโดยผู้เข้าชม
    function viewCertificate(address studentAddress) public view onlyAuthorizedViewer returns (
            string memory studentName,
            string memory studentId,
            string memory faculty,
            string memory department,
            uint256 accessTime
        )
    {
        require(
            authorizedStudent[studentAddress],
            "Student not found or unauthorized."
        );
        Student storage student = students[studentAddress];

        // ตรวจสอบเวลาการเข้าถึงของ Viewer
        //require(block.timestamp >= student.accessTime , "Viewer access time has expired.");
        //require(student.accessTime == 0, "Access time already set");

        return (student.studentName, student.studentId, student.faculty, student.department, student.accessTime);
    }
}
