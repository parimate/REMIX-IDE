// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Certificate {
    struct Student {
        string name;          // ชื่อ-นามสกุลของนักศึกษา
        uint256 studentId;    // รหัสนักศึกษา
        string faculty;       // คณะ
        string department;    // ภาควิชา
    }

    mapping(address => bool) private authorizedIssuers;  // รายชื่อผู้ที่มีสิทธิ์ในการออกใบประกาศนียบัตร
    mapping(address => bool) private authorizedViewers;  // รายชื่อผู้ที่มีสิทธิ์ในการดูข้อมูลใบประกาศนียบัตร
    mapping(address => bool) private authorizedStudent;
    mapping(address => Student) private students;        // ข้อมูลใบประกาศนียบัตรของนักศึกษา

     constructor() {
        authorizedIssuers[msg.sender] = true; // Contract creator is the initial admin
    }

    modifier onlyAuthorizedIssuer() {
        require(authorizedIssuers[msg.sender], "Only authorized issuers can call this function");
        _;
    }

    modifier onlyAuthorizedViewer() {
        require(authorizedViewers[msg.sender], "Only authorized viewers can call this function");
        _;
    }

    modifier onlyStudent() {
        require(authorizedStudent[msg.sender], "Only student can call this function");
        _;
    }

    // เพิ่มผู้ออกใบประกาศนียบัตรลงในรายชื่อผู้มีสิทธิ์
    function addAdmin(address _authorizedIssuers) external onlyAuthorizedIssuer {
        authorizedIssuers[_authorizedIssuers] = true;
    }

    // ลบผู้ออกใบประกาศนียบัตรออกจากรายชื่อผู้มีสิทธิ์
    function removeAdmin(address _authorizedIssuers) external onlyAuthorizedIssuer {
        authorizedIssuers[_authorizedIssuers] = false;
    }

    //เพิ่มผู้เข้าชมที่ได้รับสิทธิ์ในการดูข้อมูลใบประกาศนียบัตร
    function addViewer(address viewers) external onlyStudent {
        authorizedViewers[viewers] = true;
    }

    // // ลบผู้เข้าชมที่ได้รับสิทธิ์ในการดูข้อมูลใบประกาศนียบัตรออกจากรายชื่อผู้มีสิทธิ์
    // function removeViewer(address viewer) external onlyStudent {
    //     authorizedViewers[viewer] = false;
    // }

    // ออกใบประกาศนียบัตรโดยผู้ออกใบประกาศนียบัตร
    function issueCertificate(
        address studentAddress,
        string memory name,
        uint256 studentId,
        string memory faculty,
        string memory department
    ) external  onlyAuthorizedIssuer {
        authorizedStudent[studentAddress] = true; // เพิ่มที่อยู่ของนักเรียนให้กับนักเรียนที่ได้รับอนุญาต
        Student storage student = students[studentAddress];
        student.name = name;
        student.studentId = studentId;
        student.faculty = faculty;
        student.department = department;
    }

    // ดึงข้อมูลใบประกาศนียบัตรของนักศึกษา
    function getCertificate() public view returns (
        string memory name,
        uint256 studentId,
        string memory faculty,
        string memory department
    ) {
        require(authorizedStudent[msg.sender] || authorizedIssuers[msg.sender] , "You are not authorized to run this function.");
        Student storage student = students[msg.sender];
        return(student.name, student.studentId, student.faculty, student.department);
    }

    // ดึงข้อมูลใบประกาศนียบัตรของนักศึกษาโดยผู้เข้าชม
    function viewCertificate(address studentAddress) public view onlyAuthorizedViewer returns (
        string memory name,
        uint256 studentId,
        string memory faculty,
        string memory department
    ) {
        require(authorizedStudent[studentAddress], "Student not found or unauthorized.");
        Student storage student = students[studentAddress];
        return (student.name, student.studentId, student.faculty, student.department);
    }
}

