package at.fhj.swd14.pse.converter;

import java.util.Collection;
import java.util.LinkedList;
import java.util.List;
import java.util.stream.Collectors;

import at.fhj.swd14.pse.person.Person;
import at.fhj.swd14.pse.person.PersonDto;

public class PersonConverter {

    private PersonConverter() {
    }

    public static PersonDto convert(Person person) {
        if (person == null) {
            return null;
        }
        PersonDto dto = new PersonDto(person.getId());
        dto.setAddress(person.getAddress());
        dto.setFirstname(person.getFirstname());
        dto.setLastname(person.getLastname());
        dto.setImageUrl(person.getImageUrl());
        dto.setPlace(person.getPlace());
        dto.setStatus(StatusConverter.convert(person.getStatus()));
        dto.setDepartment(DepartmentConverter.convert(person.getDepartment()));
        dto.setUser(UserConverter.convert(person.getUser()));
        dto.getHobbies().clear();
        dto.getHobbies().addAll(HobbyConverter.convertToDtoList(person.getHobbies(),dto));
        dto.getKnowledges().clear();
        dto.getKnowledges().addAll(KnowledgeConverter.convertToDtoList(person.getKnowledges(),dto));
        dto.getAdditionalMails().clear();
        dto.getAdditionalMails().addAll(MailaddressConverter.convertToDtoList(person.getAdditionalMails(), dto));
        dto.getPhonenumbers().clear();
        dto.getPhonenumbers().addAll(PhonenumberConverter.convertToDtoList(person.getNumbers(), dto));

        return dto;
    }

    public static Person convert(PersonDto dto) {
        if (dto == null) {
            return null;
        }

        Person person = new Person(dto.getId(), UserConverter.convert(dto.getUser()));
        person.setAddress(dto.getAddress());
        person.setDepartment(DepartmentConverter.convert(dto.getDepartment()));
        person.setFirstname(dto.getFirstname());
        person.setImageUrl(dto.getImageUrl());
        person.setLastname(dto.getLastname());
        person.setPlace(dto.getPlace());
        person.setStatus(StatusConverter.convert(dto.getStatus()));
        person.getAdditionalMails().clear();
        person.getAdditionalMails().addAll(MailaddressConverter.convertToDoList(dto.getAdditionalMails(), person));
        person.getHobbies().clear();
        person.getHobbies().addAll(HobbyConverter.convertToDoList(dto.getHobbies(), person));
        person.getKnowledges().clear();
        person.getKnowledges().addAll(KnowledgeConverter.convertToDoList(dto.getKnowledges(), person));
        person.getNumbers().clear();
        person.getNumbers().addAll(PhonenumberConverter.convertToDoList(dto.getPhonenumbers(), person));
        return person;
    }

    public static Collection<PersonDto> convertToDtoList(Collection<Person> persons) {
        if (persons == null) {
            return null;
        }
        return persons.stream().map(PersonConverter::convert).collect(Collectors.toList());
    }

    public static Collection<Person> convertToDoList(Collection<PersonDto> persons) {
        if (persons == null) {
            return null;
        }
        List<Person> newpersons = new LinkedList<>();

        for (PersonDto dto : persons) {
            newpersons.add(convert(dto));
        }

        return newpersons;
    }

}
