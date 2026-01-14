import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:evio_core/evio_core.dart';
import '../../models/event_form_state.dart';
import '../../providers/event_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/event_form/form_header.dart';
import '../../widgets/event_form/form_details_card.dart';
import '../../widgets/event_form/form_location_card.dart';
import '../../widgets/event_form/form_lineup_card.dart';
import '../../widgets/event_form/ticket_categories_panel.dart';
import '../../widgets/event_form/form_poster_card.dart';
import '../../widgets/event_form/form_video_card.dart';
import '../../widgets/event_form/map_picker_dialog.dart';
import '../../widgets/event_form/live_preview_card.dart';
import '../../widgets/event_form/image_cropper_dialog.dart';
import '../../widgets/common/floating_snackbar.dart';

class EventFormScreen extends HookConsumerWidget {
  final String? eventId;

  const EventFormScreen({this.eventId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(eventFormNotifierProvider(eventId));
    final state = notifier.state;

    // Controllers
    final titleCtrl = useTextEditingController();
    final mainArtistCtrl = useTextEditingController();
    final genreCtrl = useTextEditingController();
    final organizerCtrl = useTextEditingController();
    final descriptionCtrl = useTextEditingController();
    final capacityCtrl = useTextEditingController();
    final priceCtrl = useTextEditingController();

    final isUpdatingFromState = useState(false);
    final hasInitialized = useState(false);

    final titleDebounce = useRef<Timer?>(null);
    final artistDebounce = useRef<Timer?>(null);
    final genreDebounce = useRef<Timer?>(null);
    final organizerDebounce = useRef<Timer?>(null);
    final descriptionDebounce = useRef<Timer?>(null);
    final capacityDebounce = useRef<Timer?>(null);
    
    // ✅ ScrollController y Keys para auto-scroll
    final scrollController = useScrollController();
    final sectionKeys = useMemoized(() => List.generate(5, (_) => GlobalKey()), []);
    
    // ✅ Estado para scroll-spy (sección activa)
    final currentSection = useState(0);
    
    // ✅ Scroll listener para detectar sección visible (scroll-spy)
    useEffect(() {
      void onScroll() {
        // Obtener posiciones de cada sección
        int visibleSection = 0;
        double minDistance = double.infinity;
        
        for (int i = 0; i < sectionKeys.length; i++) {
          final key = sectionKeys[i];
          final ctx = key.currentContext;
          if (ctx != null) {
            final box = ctx.findRenderObject() as RenderBox?;
            if (box != null && box.hasSize) {
              // Obtener posición relativa al viewport
              final position = box.localToGlobal(Offset.zero);
              // Considerar el offset del header (~120px) y un margen
              final distanceFromTop = (position.dy - 150).abs();
              
              if (distanceFromTop < minDistance) {
                minDistance = distanceFromTop;
                visibleSection = i;
              }
            }
          }
        }
        
        if (currentSection.value != visibleSection) {
          currentSection.value = visibleSection;
        }
      }
      
      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController, sectionKeys]);

    // ✅ Inicializar controllers cuando el evento se carga (modo edición)
    useEffect(() {
      // Condiciones para inicializar:
      // 1. Aún no se ha inicializado
      // 2. El state tiene datos (título no vacío)
      // 3. Los controllers están vacíos (para distinguir edición vs usuario escribiendo)
      if (!hasInitialized.value && 
          state.title.isNotEmpty && 
          titleCtrl.text.isEmpty) {
        debugPrint('🔄 Inicializando controllers con datos del state...');
        
        isUpdatingFromState.value = true;

        titleCtrl.text = state.title;
        mainArtistCtrl.text = state.mainArtist;
        genreCtrl.text = state.genre ?? '';
        organizerCtrl.text = state.organizerName ?? '';
        descriptionCtrl.text = state.description ?? '';
        capacityCtrl.text = state.totalCapacity?.toString() ?? '';

        hasInitialized.value = true;
        debugPrint('✅ Controllers initialized: ${state.title}');

        // Limpiar flag después de un frame
        Future.microtask(() {
          isUpdatingFromState.value = false;
        });
      }
      return null;
    }, [state.title]); // ✅ Escuchar cambios en state.title

    // ✅ Listeners CON DEBOUNCE de 2 segundos
    useEffect(() {
      void onTitleChanged() {
        if (isUpdatingFromState.value) return;

        titleDebounce.value?.cancel();
        titleDebounce.value = Timer(Duration(milliseconds: 300), () {
          notifier.setTitle(titleCtrl.text);
        });
      }

      void onArtistChanged() {
        if (isUpdatingFromState.value) return;

        artistDebounce.value?.cancel();
        artistDebounce.value = Timer(Duration(milliseconds: 300), () {
          notifier.setMainArtist(mainArtistCtrl.text);
        });
      }

      void onGenreChanged() {
        if (isUpdatingFromState.value) return;

        genreDebounce.value?.cancel();
        genreDebounce.value = Timer(Duration(milliseconds: 300), () {
          notifier.setGenre(genreCtrl.text.isEmpty ? null : genreCtrl.text);
        });
      }

      void onOrganizerChanged() {
        if (isUpdatingFromState.value) return;

        organizerDebounce.value?.cancel();
        organizerDebounce.value = Timer(Duration(milliseconds: 300), () {
          notifier.setOrganizerName(
            organizerCtrl.text.isEmpty ? null : organizerCtrl.text,
          );
        });
      }

      void onDescriptionChanged() {
        if (isUpdatingFromState.value) return;

        descriptionDebounce.value?.cancel();
        descriptionDebounce.value = Timer(Duration(milliseconds: 300), () {
          notifier.setDescription(
            descriptionCtrl.text.isEmpty ? null : descriptionCtrl.text,
          );
        });
      }

      void onCapacityChanged() {
        if (isUpdatingFromState.value) return;

        capacityDebounce.value?.cancel();
        capacityDebounce.value = Timer(Duration(milliseconds: 300), () {
          notifier.setTotalCapacity(int.tryParse(capacityCtrl.text));
        });
      }

      titleCtrl.addListener(onTitleChanged);
      mainArtistCtrl.addListener(onArtistChanged);
      genreCtrl.addListener(onGenreChanged);
      organizerCtrl.addListener(onOrganizerChanged);
      descriptionCtrl.addListener(onDescriptionChanged);
      capacityCtrl.addListener(onCapacityChanged);

      // Cleanup
      return () {
        titleDebounce.value?.cancel();
        artistDebounce.value?.cancel();
        genreDebounce.value?.cancel();
        organizerDebounce.value?.cancel();
        descriptionDebounce.value?.cancel();
        capacityDebounce.value?.cancel();

        titleCtrl.removeListener(onTitleChanged);
        mainArtistCtrl.removeListener(onArtistChanged);
        genreCtrl.removeListener(onGenreChanged);
        organizerCtrl.removeListener(onOrganizerChanged);
        descriptionCtrl.removeListener(onDescriptionChanged);
        capacityCtrl.removeListener(onCapacityChanged);
      };
    }, []);

    Future<void> pickAndCropImage() async {
      try {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery);

        if (image == null) return;

        final bytes = await image.readAsBytes().timeout(
          Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Timeout leyendo imagen'),
        );

        if (!context.mounted) return;

        final cropped = await showDialog<Uint8List>(
          context: context,
          builder: (_) => ImageCropperDialog(imageBytes: bytes),
        );

        if (!context.mounted) return;

        if (cropped != null) {
          notifier.setImageBytes(cropped);
        }
      } catch (e) {
        debugPrint('❌ Error en pickAndCropImage: $e');
        if (context.mounted) {
          FloatingSnackBar.show(
            context,
            message: 'Error al procesar imagen',
            type: SnackBarType.error,
          );
        }
      }
    }

    Future<void> pickFullImage() async {
      try {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery);

        if (image == null) return;

        final bytes = await image.readAsBytes().timeout(
          Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Timeout leyendo imagen'),
        );

        if (!context.mounted) return;

        notifier.setFullImageBytes(bytes);
      } catch (e) {
        debugPrint('❌ Error en pickFullImage: $e');
        if (context.mounted) {
          FloatingSnackBar.show(
            context,
            message: 'Error al cargar imagen',
            type: SnackBarType.error,
          );
        }
      }
    }

    Future<void> saveEvent() async {
      // ✅ Cancelar todos los debounces pendientes
      titleDebounce.value?.cancel();
      artistDebounce.value?.cancel();
      genreDebounce.value?.cancel();
      organizerDebounce.value?.cancel();
      descriptionDebounce.value?.cancel();
      capacityDebounce.value?.cancel();

      // ✅ Actualizar state SINCRONICAMENTE
      notifier.setTitle(titleCtrl.text);
      notifier.setMainArtist(mainArtistCtrl.text);
      notifier.setGenre(genreCtrl.text.isEmpty ? null : genreCtrl.text);
      notifier.setOrganizerName(
        organizerCtrl.text.isEmpty ? null : organizerCtrl.text,
      );
      notifier.setDescription(
        descriptionCtrl.text.isEmpty ? null : descriptionCtrl.text,
      );
      notifier.setTotalCapacity(int.tryParse(capacityCtrl.text));

      // ✅ Esperar varios frames para asegurar actualización
      await Future.delayed(Duration(milliseconds: 300));

      // ✅ Leer el state actualizado
      final currentState = notifier.state;

      final currentUser = ref.read(currentUserProvider).valueOrNull;

      if (currentUser == null) {
        if (!context.mounted) return;
        FloatingSnackBar.show(
          context,
          message: 'Error: Usuario no autenticado',
          type: SnackBarType.error,
        );
        return;
      }

      // ✅ CRÍTICO: Verificar que producerId sea el ID de la tabla producers
      if (currentUser.producerId == null) {
        if (!context.mounted) return;
        FloatingSnackBar.show(
          context,
          message: 'Error: Usuario no tiene producer asignado',
          type: SnackBarType.error,
        );
        return;
      }
      
      debugPrint('💾 [saveEvent] Guardando con producer_id: ${currentUser.producerId}');

      String? savedEventId;
      try {
        savedEventId = await notifier.save(producerId: currentUser.producerId!).timeout(
          Duration(seconds: 30),
          onTimeout: () => throw TimeoutException('Timeout guardando evento'),
        );
      } catch (e) {
        debugPrint('❌ Error guardando evento: $e');
        if (!context.mounted) return;
        FloatingSnackBar.show(
          context,
          message: 'Error de conexión al guardar',
          type: SnackBarType.error,
        );
        return;
      }

      if (!context.mounted) return;

      if (savedEventId != null) {
        context.go('/admin/dashboard');
        FloatingSnackBar.show(
          context,
          message: eventId != null
              ? 'Evento actualizado exitosamente'
              : 'Evento creado exitosamente',
          type: SnackBarType.success,
        );
      } else {
        // ✅ Leer campos faltantes DEL STATE ACTUAL
        final missing = currentState.missingFields;

        if (missing.isNotEmpty) {
          FloatingSnackBar.showValidationErrors(
            context,
            title: 'Campos requeridos para eventos "Próximos"',
            fields: missing,
            duration: Duration(seconds: 6),
          );
        } else {
          FloatingSnackBar.show(
            context,
            message: currentState.errorMessage ?? 'Error al guardar evento',
            type: SnackBarType.error,
          );
        }
      }
    }

    Future<void> selectLocation() async {
      try {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (_) => const MapPickerDialog(),
        );

        if (!context.mounted) return;

        if (result != null) {
          notifier.setLocation(
            venueName: result['venue'],
            address: result['address'],
            city: result['city'],
            lat: result['lat'],
            lng: result['lng'],
          );
        }
      } catch (e) {
        debugPrint('❌ Error en selectLocation: $e');
        if (context.mounted) {
          FloatingSnackBar.show(
            context,
            message: 'Error al seleccionar ubicación',
            type: SnackBarType.error,
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: EvioLightColors.surface,
      body: Column(
        children: [
          FormHeader(
            isEdit: eventId != null,
            onCancel: () => context.pop(),
            onSave: saveEvent,
            isLoading: state.isSaving,
            status: state.status,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 1100;

                if (isDesktop) {
                  void scrollToSection(int index) {
                    // Actualizar sección activa inmediatamente
                    currentSection.value = index;
                    
                    final key = sectionKeys[index];
                    final ctx = key.currentContext;
                    if (ctx != null) {
                      Scrollable.ensureVisible(
                        ctx,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  }
                  
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sidebar de navegación de secciones
                      _FormSectionNav(
                        onSectionTap: scrollToSection,
                        activeIndex: currentSection.value,
                      ),
                      
                      // Contenido del formulario
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: EdgeInsets.all(EvioSpacing.xl),
                          child: _buildFormContent(
                            context,
                            ref,
                            state,
                            titleCtrl,
                            mainArtistCtrl,
                            genreCtrl,
                            organizerCtrl,
                            descriptionCtrl,
                            capacityCtrl,
                            priceCtrl,
                            selectLocation,
                            pickAndCropImage,
                            pickFullImage,
                            notifier,
                            sectionKeys: sectionKeys,
                          ),
                        ),
                      ),
                      // Panel de preview
                      SizedBox(
                        width: 380,
                        child: Container(
                          color: EvioLightColors.surface,
                          padding: EdgeInsets.all(EvioSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Vista de Usuario',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: EvioLightColors.textPrimary,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: EvioSpacing.sm,
                                      vertical: EvioSpacing.xxs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: EvioLightColors.muted,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Mobile Preview',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: EvioLightColors.mutedForeground,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: EvioSpacing.lg),
                              Expanded(
                                child: Center(
                                  child: LivePreviewCard(
                                    title: state.title,
                                    mainArtist: state.mainArtist,
                                    date: state.startDatetime,
                                    venue: state.venueName,
                                    city: state.city,
                                    description: state.description,
                                    organizerName: state.organizerName,
                                    lineup: state.lineup,
                                    categories: state.ticketCategories,
                                    imageBytes: state.imageBytes,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(EvioSpacing.xl),
                    child: Column(
                      children: [
                        _buildFormContent(
                          context,
                          ref,
                          state,
                          titleCtrl,
                          mainArtistCtrl,
                          genreCtrl,
                          organizerCtrl,
                          descriptionCtrl,
                          capacityCtrl,
                          priceCtrl,
                          selectLocation,
                          pickAndCropImage,
                          pickFullImage,
                          notifier,
                        ),
                        SizedBox(height: EvioSpacing.xxl),
                        Divider(color: EvioLightColors.border),
                        SizedBox(height: EvioSpacing.xl),
                        Text('Vista Previa', style: EvioTypography.h3),
                        SizedBox(height: EvioSpacing.md),
                        LivePreviewCard(
                          title: state.title,
                          mainArtist: state.mainArtist,
                          date: state.startDatetime,
                          venue: state.venueName,
                          city: state.city,
                          description: state.description,
                          organizerName: state.organizerName,
                          lineup: state.lineup,
                          categories: state.ticketCategories,
                          imageBytes: state.imageBytes,
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(
    BuildContext context,
    WidgetRef ref,
    EventFormState state,
    TextEditingController titleCtrl,
    TextEditingController mainArtistCtrl,
    TextEditingController genreCtrl,
    TextEditingController organizerCtrl,
    TextEditingController descriptionCtrl,
    TextEditingController capacityCtrl,
    TextEditingController priceCtrl,
    Future<void> Function() selectLocation,
    Future<void> Function() pickAndCropImage,
    Future<void> Function() pickFullImage,
    EventFormNotifier notifier, {
    List<GlobalKey>? sectionKeys,
  }) {
    return Column(
      children: [
        // 0: Detalles
        RepaintBoundary(
          key: sectionKeys?[0],
          child: FormDetailsCard(
            titleCtrl: titleCtrl,
            mainArtistCtrl: mainArtistCtrl,
            genreCtrl: genreCtrl,
            organizerCtrl: organizerCtrl,
            descriptionCtrl: descriptionCtrl,
            status: state.status,
            onStatusChanged: (status) => notifier.setStatus(status),
          ),
        ),
        SizedBox(height: EvioSpacing.xl),
        // 1: Ubicación
        RepaintBoundary(
          key: sectionKeys?[1],
          child: FormLocationCard(
          startDate: state.startDatetime,
          startTime: TimeOfDay.fromDateTime(state.startDatetime),
          venueName: state.venueName,
          city: state.city,
          onDateChanged: (date) => notifier.setStartDatetime(date),
          onTimeChanged: (time) {
            final newDate = DateTime(
              state.startDatetime.year,
              state.startDatetime.month,
              state.startDatetime.day,
              time.hour,
              time.minute,
            );
            notifier.setStartDatetime(newDate);
          },
          onSelectLocation: selectLocation,
          ),
        ),
        SizedBox(height: EvioSpacing.xl),
        // 2: Tickets
        RepaintBoundary(
          key: sectionKeys?[2],
          child: TicketCategoriesPanel(eventId: eventId),
        ),
        SizedBox(height: EvioSpacing.xl),
        // 3: DJs
        RepaintBoundary(
          key: sectionKeys?[3],
          child: FormLineupCard(
          lineup: state.lineup,
          onAdd: (name, isHeadliner, imageUrl) {
            // ✅ Instantáneo con imageUrl de Spotify
            notifier.addArtist(name, isHeadliner: isHeadliner, imageUrl: imageUrl);
          },
          onRemove: (index) => notifier.removeArtist(index),
          onToggleHeadliner: (index) => notifier.toggleHeadliner(index),
          ),
        ),
        SizedBox(height: EvioSpacing.xl),
        // 4: Póster
        RepaintBoundary(
          key: sectionKeys?[4],
          child: FormPosterCard(
          croppedImageBytes: state.imageBytes,
          fullImageBytes: state.fullImageBytes,
          imageType: state.imageType,
          onImageTypeChanged: (type) => notifier.setImageType(type),
          onUploadCropped: pickAndCropImage,
          onUploadFull: pickFullImage,
          onRemove: () => notifier.clearImage(),
          ),
        ),
        SizedBox(height: EvioSpacing.xl),
        // Video
        RepaintBoundary(
          child: FormVideoCard(
            videoUrl: state.videoUrl,
            onChanged: (url) => notifier.setVideoUrl(url),
          ),
        ),
        SizedBox(height: 100),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// FORM SECTION NAVIGATION
// -----------------------------------------------------------------------------

class _FormSectionNav extends StatelessWidget {
  final ValueChanged<int> onSectionTap;
  final int activeIndex;
  
  const _FormSectionNav({
    required this.onSectionTap,
    required this.activeIndex,
  });

  static const _sections = [
    ('Detalles', Icons.music_note_outlined),
    ('Ubicación', Icons.location_on_outlined),
    ('Tickets', Icons.confirmation_number_outlined),
    ('DJs', Icons.people_outline),
    ('Póster', Icons.image_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: EdgeInsets.symmetric(
        vertical: EvioSpacing.xl,
        horizontal: EvioSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < _sections.length; i++)
            _SectionNavItem(
              icon: _sections[i].$2,
              label: _sections[i].$1,
              isActive: i == activeIndex,
              onTap: () => onSectionTap(i),
            ),
        ],
      ),
    );
  }
}

class _SectionNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SectionNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: EvioSpacing.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EvioRadius.button),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: EvioSpacing.sm,
            vertical: EvioSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EvioRadius.button),
          ),
          child: Row(
            children: [
              // Icono con fondo amarillo si activo
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isActive 
                      ? EvioLightColors.accent 
                      : EvioLightColors.muted,
                  borderRadius: BorderRadius.circular(EvioRadius.button),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isActive 
                      ? EvioLightColors.accentForeground 
                      : EvioLightColors.mutedForeground,
                ),
              ),
              SizedBox(width: EvioSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive 
                        ? EvioLightColors.textPrimary 
                        : EvioLightColors.mutedForeground,
                  ),
                ),
              ),
              // Indicador vertical amarillo si activo
              if (isActive)
                Container(
                  width: 3,
                  height: 20,
                  decoration: BoxDecoration(
                    color: EvioLightColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
