package com.condos.incidente.service;

import com.condos.common.exceptions.ResourceNotFoundException;
import com.condos.common.utils.TenantContext;
import com.condos.condominio.model.Condominio;
import com.condos.condominio.repository.CondominioRepository;
import com.condos.incidente.dto.CategoriaIncidenteResponse;
import com.condos.incidente.dto.CreateCategoriaRequest;
import com.condos.incidente.model.CategoriaIncidenteEntity;
import com.condos.incidente.repository.CategoriaIncidenteRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class CategoriaIncidenteService {

    private final CategoriaIncidenteRepository categoriaRepository;
    private final CondominioRepository condominioRepository;

    @Transactional(readOnly = true)
    public List<CategoriaIncidenteResponse> listarCategorias(boolean soloActivas) {
        Long condominioId = TenantContext.getCondominioId();
        List<CategoriaIncidenteEntity> categorias = soloActivas
                ? categoriaRepository.findByCondominioIdAndActivaOrderByNombreAsc(condominioId, true)
                : categoriaRepository.findByCondominioIdOrderByNombreAsc(condominioId);
        return categorias.stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional
    public CategoriaIncidenteResponse crearCategoria(CreateCategoriaRequest request) {
        Long condominioId = TenantContext.getCondominioId();

        if (categoriaRepository.existsByCondominioIdAndNombre(condominioId, request.getNombre().trim())) {
            throw new IllegalArgumentException("Ya existe una categoría con ese nombre");
        }

        Condominio condominio = condominioRepository.findById(condominioId)
                .orElseThrow(() -> new ResourceNotFoundException("Condominio no encontrado"));

        CategoriaIncidenteEntity cat = CategoriaIncidenteEntity.builder()
                .condominio(condominio)
                .nombre(request.getNombre().trim())
                .activa(true)
                .build();

        cat = categoriaRepository.save(cat);
        log.info("Categoría de incidente creada: id={}, nombre={}", cat.getId(), cat.getNombre());
        return toResponse(cat);
    }

    @Transactional
    public CategoriaIncidenteResponse toggleActiva(Long id) {
        CategoriaIncidenteEntity cat = categoriaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Categoría no encontrada"));
        cat.setActiva(!cat.isActiva());
        cat = categoriaRepository.save(cat);
        log.info("Categoría {} activa: {}", id, cat.isActiva());
        return toResponse(cat);
    }

    private CategoriaIncidenteResponse toResponse(CategoriaIncidenteEntity cat) {
        return CategoriaIncidenteResponse.builder()
                .id(cat.getId())
                .nombre(cat.getNombre())
                .activa(cat.isActiva())
                .build();
    }
}
