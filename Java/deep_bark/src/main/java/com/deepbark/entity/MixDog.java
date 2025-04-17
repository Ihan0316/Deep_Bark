package com.deepbark.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "mix_dogs")
@Getter
@Setter
public class MixDog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String nameEn;
    private String nameKo;
    private String breed1;
    private String breed2;
}
