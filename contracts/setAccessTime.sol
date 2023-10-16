// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Certificate {
    struct Student {
        address studentAddress; // Address นักศึกษา
        string certificateName; // ชื่อใบประกาศนียบัตร
        string studentName;     // ชื่อ-นามสกุลของนักศึกษา
        string studentId;       // รหัสนักศึกษา
        string faculty;         // คณะ
        string department;      // ภาควิชา
        uint256 accessTime;     // เวลาที่อนุญาตให้เข้าดูข้อมูล
        bool revokedStatus;     // สถานะเพิกถอนใบประกาศนียบัตร
        string issuedName;      // ชื่อผู้ออกใบประกาศนียบัตร
        address issuedAddress; 
    }

    struct Admin {
        address addminAddress;  // Address Admin
        string name;            // ชื่อ-นามสกุล
        string adminId;         // รหัสประจำตัว
        string position;        // ตำแหน่งหน้าที่
        bool adminStatus;       // สถานะ admin
    }

    Student[] public _StudentCertificate;
    Admin[] public _allAdmin;

    mapping(address => bool) private authorizedIssuers; // รายชื่อผู้ที่มีสิทธิ์ในการออกใบประกาศนียบัตร
    mapping(address => bool) private authorizedViewers; // รายชื่อผู้ที่มีสิทธิ์ในการดูข้อมูลใบประกาศนียบัตร
    mapping(address => bool) private authorizedStudent; // รายชื่อนักศึกษาเจ้าของใบประกาศนียบัตร
    mapping(address => Student) private students;       // ข้อมูลใบประกาศนียบัตรของนักศึกษา
    mapping(address => Admin) private admins;           // ข้อมูลใบผู้ที่มีสิทธิ์ในการออกใบประกาศนียบัตร
    mapping(address => uint256) private viewerAccessTimes; // เก็บเวลาการเข้าถึงของผู้เข้าชม

    constructor() {
        authorizedIssuers[msg.sender] = true; // Contract creator is the initial admin
    }

    modifier onlyAuthorizedIssuer() {
        require(
            authorizedIssuers[msg.sender],
            "Only authorized issuers can call this function"
        );
        _;
    }

    modifier onlyAuthorizedViewer() {
        require(
            authorizedViewers[msg.sender],
            "Only authorized viewers can call this function"
        );
        _;
    }

    modifier onlyStudent() {
        require(
            authorizedStudent[msg.sender],
            "Only student can call this function"
        );
        _;
    }

    //----------------------------------------------------------------------------------------------//

    // เพิ่มรายชื่อผู้มีสิทธิ์ออกใบประกาศนียบัตร
    function addAdmin(address addminAddress, string memory name, string memory adminId, string memory position) external onlyAuthorizedIssuer {
        authorizedIssuers[addminAddress] = true;
        Admin storage admin = admins[addminAddress];
        admin.addminAddress = addminAddress;
        admin.name = name;
        admin.adminId = adminId;
        admin.position = position;
        admin.adminStatus = true;
        _allAdmin.push(Admin(addminAddress, name, adminId, position, true));
    }

    // ลบรายชื่อออกจากผู้มีสิทธิ์ออกใบประกาศนียบัตร
    function removeAdmin(address addminAddress) external onlyAuthorizedIssuer{
        authorizedIssuers[addminAddress] = false;
        Admin storage admin = admins[addminAddress];
        admin.adminStatus = false;

        for (uint i = 0; i < _allAdmin.length; i++) {
            if (_allAdmin[i].addminAddress == addminAddress) {
                _allAdmin[i].adminStatus = false;
                 break;  // หากพบ admin แล้วก็ออกจาก loop
            }
        }
    }

    // function getAdmin() public view returns (
    //         string memory name,
    //         string memory id,
    //         string memory position
    //     )
    // {
    //     require(authorizedIssuers[msg.sender],"You are not authorized to run this function.");
    //     Admin storage admin = admins[msg.sender];
    //     return (admin.name, admin.adminId, admin.position);
    // }

    // function viewAdmin() public view onlyAuthorizedIssuer returns (Admin[] memory) {
    //     require(authorizedIssuers[msg.sender],"You are not authorized to run this function.");
    //     uint256 numAdmin = _allAdmin.length;
    //     Admin[] memory Admins = new Admin[](numAdmin);

    //     for (uint256 i = 0; i < numAdmin; i++) {
    //         Admins[i] = _allAdmin[i];
    //     }

    //     return Admins;
    // }

    //----------------------------------------------------------------------------------------------//

    // //เพิ่มผู้เข้าชมที่ได้รับสิทธิ์และกำหนดเวลาในการดูข้อมูลใบประกาศนียบัตร
    // function addViewer(address viewers, uint256 timestamp)
    //     external
    //     onlyStudent
    // {
    //     Student storage student = students[msg.sender];
    //     student.accessTime = block.timestamp + timestamp;
    //     authorizedViewers[viewers] = true;
    // }

    // // ลบผู้เข้าชมที่ได้รับสิทธิ์ในการดูข้อมูลใบประกาศนียบัตรออกจากรายชื่อผู้มีสิทธิ์
    // function removeViewer(address viewer) external onlyStudent {
    //     authorizedViewers[viewer] = false;
    // }

    //----------------------------------------------------------------------------------------------//

    // ออกใบประกาศนียบัตรโดยผู้ออกใบประกาศนียบัตร
    function issueCertificate(
        address studentAddress,
        string memory certificateName, 
        string memory studentName,
        string memory studentId,
        string memory faculty,
        string memory department
    ) external onlyAuthorizedIssuer {
        authorizedStudent[studentAddress] = true; // เพิ่มที่อยู่ของนักเรียนให้กับนักเรียนที่ได้รับอนุญาต
        Student storage student = students[studentAddress];
        student.studentAddress = studentAddress;
        student.certificateName = certificateName;
        student.studentName = studentName;
        student.studentId = studentId;
        student.faculty = faculty;
        student.department = department;
        student.accessTime = 0;
        student.revokedStatus = false;
        student.issuedAddress = msg.sender;
        student.issuedName = admins[msg.sender].name;

        _StudentCertificate.push(
            Student(
                studentAddress,
                certificateName,
                studentName,
                studentId,
                faculty,
                department,
                0,
                false,
                admins[msg.sender].name,
                address(msg.sender)
            )
        );
    }

    function revokeCertificate(address studentAddress) external onlyAuthorizedIssuer{
        Student storage student = students[studentAddress];
        student.revokedStatus = true;

        for (uint i = 0; i < _StudentCertificate.length; i++) {
            if (_StudentCertificate[i].studentAddress == studentAddress) {
                _StudentCertificate[i].revokedStatus = true;
                 break;  
            }
        }
    }

    // function viewStudent() public view returns (Student[] memory) {
    //     uint256 numCertificates = StudentCertificate.length;
    //     Student[] memory certificates = new Student[](numCertificates);

    //     for (uint256 i = 0; i < numCertificates; i++) {
    //         certificates[i] = StudentCertificate[i];
    //     }

    //     return certificates;
    // }

    //  // กำหนดเวลาในการดูข้อมูลใบประกาศนียบัตร
    // function setAccessTime(uint256 timestamp) external onlyAuthorizedViewer {
    //     Student storage student = students[msg.sender];
    //     require(student.accessTime == 0, "Access time already set");
    //     require(timestamp > block.timestamp, "Access time should be in the future");
    //     student.accessTime = timestamp;
    // }

    // // ดึงข้อมูลใบประกาศนียบัตรของนักศึกษา
    // function getCertificate() public view returns (
    //         string memory studentName,
    //         string memory studentId,
    //         string memory faculty,
    //         string memory department
    //     )
    // {
    //     require(
    //         authorizedStudent[msg.sender] || authorizedIssuers[msg.sender],
    //         "You are not authorized to run this function."
    //     );
    //     Student storage student = students[msg.sender];
    //     return (student.studentName, student.studentId, student.faculty, student.department);
    // }

    // // ดึงข้อมูลใบประกาศนียบัตรของนักศึกษาโดยผู้เข้าชม
    // function viewCertificate(address studentAddress) public view onlyAuthorizedViewer returns (
    //         string memory studentName,
    //         string memory studentId,
    //         string memory faculty,
    //         string memory department,
    //         uint256 accessTime
    //     )
    // {
    //     require(
    //         authorizedStudent[studentAddress],
    //         "Student not found or unauthorized."
    //     );
    //     Student storage student = students[studentAddress];

    //     // ตรวจสอบเวลาการเข้าถึงของ Viewer
    //     //require(block.timestamp >= student.accessTime , "Viewer access time has expired.");
    //     //require(student.accessTime == 0, "Access time already set");

    //     return (student.studentName, student.studentId, student.faculty, student.department, student.accessTime);
    // }
}
