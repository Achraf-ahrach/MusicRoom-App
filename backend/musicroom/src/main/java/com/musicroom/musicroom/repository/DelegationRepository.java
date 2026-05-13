package com.musicroom.musicroom.repository;

import com.musicroom.musicroom.entity.Delegation;
import com.musicroom.musicroom.enums.ResourceType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface DelegationRepository extends JpaRepository<Delegation, UUID> {

    List<Delegation> findByResourceTypeAndResourceId(
            ResourceType resourceType,
            UUID resourceId
    );

    Optional<Delegation> findByDelegateIdAndResourceTypeAndResourceId(
            UUID delegateId,
            ResourceType resourceType,
            UUID resourceId
    );

    boolean existsByDelegateIdAndResourceTypeAndResourceId(
            UUID delegateId,
            ResourceType resourceType,
            UUID resourceId
    );

    List<Delegation> findByDelegateId(UUID delegateId);

    boolean existsByDelegateIdAndResourceIdAndResourceTypeAndActiveTrue(
            UUID delegateId,
            UUID resourceId,
            ResourceType resourceType
    );

    List<Delegation> findByDelegateIdAndResourceIdAndResourceType(
            UUID delegateId,
            UUID resourceId,
            ResourceType resourceType
    );
}

