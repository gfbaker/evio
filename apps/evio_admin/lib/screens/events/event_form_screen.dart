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
import '../../widgets/event_form/form_capacity_pricing_card.dart';
import '../../widgets/event_form/ticket_categories_panel.dart';
import '../../widgets/event_form/form_features_card.dart';
import '../../widgets/event_form/form_poster_card.dart';
import '../../widgets/event_form/form_video_card.dart';
import '../../widgets/event_form/map_picker_dialog.dart';
import '../../widgets/event_form/live_preview_card.dart';
import '../../widgets/event_form/live_preview_detail.dart';
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
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!context.mounted) return;

      final cropped = await showDialog<Uint8List>(
        context: context,
        builder: (_) => ImageCropperDialog(imageBytes: bytes),
      );

      if (cropped != null) {
        // ✅ Instantáneo (sin debounce)
        notifier.setImageBytes(cropped);
      }
    }

    Future<void> pickFullImage() async {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final bytes = await image.readAsBytes();

      // Guardar imagen completa sin crop
      notifier.setFullImageBytes(bytes);
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

      final savedEventId = await notifier.save(producerId: currentUser.id);

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
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => const MapPickerDialog(),
      );

      if (result != null) {
        // ✅ Instantáneo (sin debounce)
        notifier.setLocation(
          venueName: result['venue'],
          address: result['address'],
          city: result['city'],
          lat: result['lat'],
          lng: result['lng'],
        );
      }
    }

    return Scaffold(
      backgroundColor: EvioLightColors.background,
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
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
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
                          ),
                        ),
                      ),
                      VerticalDivider(width: 1, color: EvioLightColors.border),
                      Expanded(
                        flex: 1,
                        child: Container(
                          color: EvioLightColors.surface,
                          padding: EdgeInsets.all(EvioSpacing.xl),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Vista de Usuario',
                                    style: EvioTypography.h3,
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: EvioSpacing.xs,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: EvioLightColors.border,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.white,
                                    ),
                                    child: Text(
                                      'App Preview',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: EvioLightColors.mutedForeground,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: EvioSpacing.lg),
                              Expanded(
                                child: RepaintBoundary(
                                  child: LivePreviewDetail(
                                  title: state.title,
                                  mainArtist: state.mainArtist,
                                  date: state.startDatetime,
                                  venueName: state.venueName,
                                  city: state.city,
                                  description: state.description,
                                  lineup: state.lineup,
                                  ticketTypes: state.ticketTypes,
                                  showAllTicketTypes: state.showAllTicketTypes,
                                  features: state.features,
                                  imageBytes: state.imageBytes,
                                  videoUrl: state.videoUrl,
                                  lat: state.lat,
                                  lng: state.lng,
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
                          date: state.startDatetime,
                          venue: state.venueName,
                          city: state.city,
                          price: priceCtrl.text,
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
    EventFormNotifier notifier,
  ) {
    return Column(
      children: [
        RepaintBoundary(
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
        RepaintBoundary(
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
        // ✅ NUEVO PANEL DE CATEGORÍAS Y TIERS
        RepaintBoundary(
          child: TicketCategoriesPanel(eventId: eventId),
        ),
        SizedBox(height: EvioSpacing.xl),
        RepaintBoundary(
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
        RepaintBoundary(
          child: FormFeaturesCard(
          selectedFeatures: state.features,
          onToggle: (feature) => notifier.toggleFeature(feature),
          ),
        ),
        SizedBox(height: EvioSpacing.xl),
        RepaintBoundary(
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
