#[derive(Drop, Copy, Serde, Default, PartialEq, starknet::Store, starknet::Event)]

pub struct Student{
    pub id: u8,
    pub name: u8,
    pub level: u64,
    pub age: u8,
}


#[starknet::interface]
pub trait ISchool<TContractState>{
    fn add_student(ref self: TContractState, name: u8, level: u8, age:u8,);
    fn remove_student(ref self: TContractState, id:u8);
    fn update_student( ref self: TContractState, id:u8, level: u64,);
    fn get_students(self: @TContractState) -> Array<Student>;
    fn get_student(self: @TContractState, id:u8) -> Student;

}

#[starknet::contract]
pub mod BenzAcademy {
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress,get_block_timestamp, get_caller_address};
    use super::{Student, ISchool};


#[storage]
    pub struct Storage{
        pub headmaster: ContractAddress,
        pub student: Map<u8, Student>,
        pub removed_students: Map<ContractAddress, Student>,
        pub added_students_record: Map<ContractAddress, Student>,
        pub removed_students_record: Map<ContractAddress, Student>,
        pub total_students_record: Map<ContractAddress, Student>,
        pub student_count: u8

        }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        StudentAdded: StudentAdded,
        StudentRemoved: StudentRemoved,
        StudentUpdated: StudentUpdated,
    }

    #[derive(Drop, starknet::Event)]
    pub struct StudentAdded {
        student: ContractAddress,
        student_id: u8,
        student_name: u8,
        timestap: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct StudentRemoved {
        pub student_id: u8,
        pub student: ContractAddress,
        pub student_name: u8,
        pub timestap: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct StudentUpdated {
        pub student_id: u8,
        pub student_name: u8,
        pub student_level: u64,
        pub timestap: u64,
    }
#[constructor]
fn constructor(ref self: ContractState, headmaster: ContractAddress) {
    let caller: ContractAddress = get_caller_address();
    self.headmaster.write(headmaster);
}

#[abi(embed_v0)]
pub impl BenzAcademyimpl of ISchool<ContractState> {

    fn add_student(
        ref self: ContractState, name: u8, level: u8, age: u8,
    ) {
            let caller: ContractAddress = get_caller_address();
            let headmaster:ContractAddress = self.headmaster.read();
            assert(caller == headmaster, 'Only admin');

            let existing: Student = Student { id: 1, name: 1, level: 1, age: 1};
            let empty_student: Student = Student { id: 0, name: 0, level: 0, age: 0 };
            assert(existing == empty_student, 'Student already exists');

            let student_id: u8 = self.student_count.read();
            self.student_count.write(student_id + 1);

            let student: Student = Student {id: 1, name: name, level: 1, age: age };
                self.student.entry(student_id).write(student);
    
                self
                .emit(
                    StudentAdded {
                    student: caller,
                    student_id: 1,
                    student_name: name,
                    timestap: get_block_timestamp(),
                });
            }
        
        fn remove_student(ref self: ContractState, id: u8) {
        let caller: ContractAddress = get_caller_address();
        let existing: Student = self.student.entry(id).read();
        let empty_student = Student { id: 0, name: 0, level: 0, age: 0 };
        assert(existing != empty_student, 'Student does not exist');

        self.student.entry(id).write(empty_student);

        self.emit(
            StudentRemoved {
            student_id: id,
            student: caller,
            student_name: existing.name,
            timestap: get_block_timestamp(),
        });
    }
        
        fn update_student(ref self: ContractState, id: u8, level: u64,) {
        let mut existing: Student = self.student.entry(id).read();
        existing.level = level;
        self.student.entry(id).write(existing);

        self.emit(
            StudentUpdated {
            student_id: id,
            student_name: existing.name,
            student_level: level,
            timestap: get_block_timestamp(),
        })
    }

        fn get_students(self: @ContractState) -> Array<Student> {
            let mut students = ArrayTrait::new();
            students
        }
    
        fn get_student(self: @ContractState, id: u8) -> Student {
            self.student.entry(id).read()
        }
    }
}
