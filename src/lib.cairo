use BenzAcademy::ContractState;
use starknet::storage::StoragePointerWriteAccess;
use starknet::event::EventEmitter;
use starknet::storage::StorageMapWriteAccess;
use starknet::storage::StorageMapReadAccess;
use starknet::storage::StoragePointerReadAccess;
use starknet::get_caller_address;
use starknet::get_block_timestamp;
use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, PartialEq, starknet::Store, Default)]

pub struct Student{
    pub id: u8,
    pub name: felt252,
    pub level: u64,
    pub age: u8,
}


#[starknet::interface]
pub trait ISchool<TContractState>{
    fn add_student(ref self: TContractState, name: felt252, level: u64, age:u8,);
    fn remove_student(ref self: TContractState, id:u8);
    fn update_student( ref self: TContractState, id:u8, level: u64,);
    fn get_students(self: @TContractState) -> Array<Student>;
    fn get_student(self: @TContractState, id:u8) -> Student;

}

#[starknet::contract]
pub mod BenzAcademy {
use starknet::get_block_timestamp;
use crate::StorageMapWriteAccess;
use crate::StorageMapReadAccess;
use crate::ISchool;
use crate::ISchoolDispatcherTrait;
use crate::BenzAcademy;
use super::Student;
    use starknet::ContractAddress;
    use starknet::storage::{Map, StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry};
    use starknet::get_caller_address;

#[storage]
    pub struct Storage{
        pub headmaster: ContractAddress,
        pub student: Map<u8, Student>,
        pub removed_students: Map<ContractAddress, Student>,
        pub added_students_record: Map<ContractAddress, Student>,
        pub removed_students_record: Map<ContractAddress, Student>,
        pub total_students_record: Map<ContractAddress, u256>,

        }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        StudentAdded: StudentAddedEvent,
        StudentRemoved: StudentRemovedEvent,
        StudentUpdated: StudentUpdatedEvent,
    }

    #[derive(Drop, starknet::Event)]
    pub struct StudentAddedEvent {
        student: ContractAddress,
        student_id: u8,
        student_name: felt252,
        timestap: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct StudentRemovedEvent {
        pub student_id: u8,
        pub student: ContractAddress,
        pub student_name: felt252,
        pub timestap: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct StudentUpdatedEvent {
        pub student_id: u8,
        pub student_name: felt252,
        pub student_level: u64,
        pub timestap: u64,
    }
#[constructor]
fn constructor(ref self: ContractState, headmaster: ContractAddress) {
    self.headmaster.write(headmaster);
}

fn only_admin(ref self: ContractState) {
    let caller: ContractAddress = get_caller_address();
    let headmaster = self.headmaster.read();
    assert(caller == headmaster, 'Only admin');
}

#[abi(embed_v0)]
impl BenzAcademyimpl of ISchool<ContractState> {

    fn add_student(
        ref self: ContractState, name: felt252, level: u64, age: u8,
    ) {
            let caller: ContractAddress = get_caller_address();
            let headmaster = self.headmaster.read();
            assert(caller == headmaster, 'Only admin');

            let existing = self.student.read(1);
            let empty_student = Student { id: 0, name: 0, level: 0, age: 0 };
            assert(existing == empty_student, 'Student already exists');

                let student = Student { id: 1, name, age, level };
                self.student.write(1, student);
    
                self.emit(Event::StudentAdded(StudentAddedEvent {
                    student: caller,
                    student_id: 1,
                    student_name: name,
                    timestap: get_block_timestamp(),
                }));
            }
        
        fn remove_student(ref self: ContractState, id: u8) {
        let caller: ContractAddress = get_caller_address();
        let existing = self.student.read(id);
        let empty_student = Student { id: 0, name: 0, level: 0, age: 0 };
        assert(existing != empty_student, 'Student does not exist');

        self.student.write(id, empty_student);

        let count = self.total_students_record.read(caller);
        self.total_students_record.write(caller, count - 1);

        self.emit(Event::StudentRemoved(StudentRemovedEvent {
            student_id: id,
            student: caller,
            student_name: existing.name,
            timestap: get_block_timestamp(),
        }));
    }
        
        fn update_student(
            ref self: ContractState, id: u8, level: u64,
    ) {
        let mut existing = self.student.read(id);
        existing.level = level;
        self.student.write(id, existing);

        self.emit(Event::StudentUpdated(StudentUpdatedEvent {
            student_id: id,
            student_name: existing.name,
            student_level: level,
            timestap: get_block_timestamp(),
        }));
    }

        fn get_students(self: @ContractState) -> Array<Student> {
            let mut students = ArrayTrait::new();
            students
        }
    
        fn get_student(self: @ContractState, id: u8) -> Student {
            self.student.read(id)
        }
    }
}
