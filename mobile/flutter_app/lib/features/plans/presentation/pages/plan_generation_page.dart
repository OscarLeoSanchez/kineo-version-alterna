import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../auth/data/services/auth_session_store.dart';
import '../../data/services/plan_sse_api_service.dart';

// ---------------------------------------------------------------------------
// Internal state model
// ---------------------------------------------------------------------------

class _Step {
  final String label;
  final bool done;

  const _Step({required this.label, required this.done});

  _Step copyWith({String? label, bool? done}) {
    return _Step(label: label ?? this.label, done: done ?? this.done);
  }
}

class _PlanGenState {
  final List<_Step> steps;
  final double progress;
  final bool isDone;
  final String? error;
  final Map<String, dynamic> plan;

  const _PlanGenState({
    this.steps = const [],
    this.progress = 0,
    this.isDone = false,
    this.error,
    this.plan = const {},
  });

  _PlanGenState copyWith({
    List<_Step>? steps,
    double? progress,
    bool? isDone,
    String? error,
    Map<String, dynamic>? plan,
  }) {
    return _PlanGenState(
      steps: steps ?? this.steps,
      progress: progress ?? this.progress,
      isDone: isDone ?? this.isDone,
      error: error,
      plan: plan ?? this.plan,
    );
  }
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class PlanGenerationPage extends StatefulWidget {
  const PlanGenerationPage({super.key});

  @override
  State<PlanGenerationPage> createState() => _PlanGenerationPageState();
}

class _PlanGenerationPageState extends State<PlanGenerationPage>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<_PlanGenState> _stateNotifier =
      ValueNotifier(const _PlanGenState());

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startGeneration();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stateNotifier.dispose();
    super.dispose();
  }

  Future<void> _startGeneration() async {
    // Reset state
    _stateNotifier.value = const _PlanGenState();

    final session = await AuthSessionStore().load();
    if (session == null) {
      _stateNotifier.value = _stateNotifier.value.copyWith(
        error: 'No hay sesion activa. Inicia sesion e intenta de nuevo.',
      );
      return;
    }

    final service = PlanSseApiService(
      baseUrl: AppConfig.apiBaseUrl,
      accessToken: session.accessToken,
    );

    await for (final event in service.streamGeneration()) {
      if (!mounted) return;
      final current = _stateNotifier.value;

      if (event is PlanGenerationProgress) {
        // Mark the previous current step as done and add the new one
        final updatedSteps = current.steps.map((s) {
          if (!s.done) return s.copyWith(done: true);
          return s;
        }).toList();
        updatedSteps.add(_Step(label: event.label, done: false));

        _stateNotifier.value = current.copyWith(
          steps: updatedSteps,
          progress: event.pct.toDouble(),
        );
      } else if (event is PlanGenerationDone) {
        final updatedSteps =
            current.steps.map((s) => s.copyWith(done: true)).toList();
        _stateNotifier.value = current.copyWith(
          steps: updatedSteps,
          progress: 100,
          isDone: true,
          plan: event.plan,
        );
        _pulseController.stop();
      } else if (event is PlanGenerationError) {
        _stateNotifier.value = current.copyWith(error: event.message);
        _pulseController.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generando tu plan'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ValueListenableBuilder<_PlanGenState>(
          valueListenable: _stateNotifier,
          builder: (context, state, _) {
            if (state.error != null) {
              return _buildErrorState(context, state.error!);
            }
            if (state.isDone) {
              return _buildDoneState(context, state);
            }
            return _buildProgressState(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildProgressState(BuildContext context, _PlanGenState state) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      children: [
        // Icon
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFD6EEE6),
              borderRadius: BorderRadius.circular(44),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 44,
              color: Color(0xFF143C3A),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          'Construyendo tu plan personalizado',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Tu coach IA esta analizando tu perfil y objetivos.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: state.progress / 100),
            duration: const Duration(milliseconds: 400),
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor:
                  theme.colorScheme.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF143C3A),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${state.progress.round()}%',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.end,
        ),
        const SizedBox(height: 24),

        // Step list
        if (state.steps.isNotEmpty) ...[
          Text('Pasos', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ...state.steps.map((step) => _buildStepTile(context, step)),
        ],
      ],
    );
  }

  Widget _buildStepTile(BuildContext context, _Step step) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (step.done)
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF2E7D52),
              size: 22,
            )
          else
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) => Opacity(
                opacity: _pulseAnimation.value,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF143C3A),
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: step.done
                    ? theme.colorScheme.onSurface.withOpacity(0.5)
                    : theme.colorScheme.onSurface,
                decoration:
                    step.done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneState(BuildContext context, _PlanGenState state) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFD6EEE6),
              borderRadius: BorderRadius.circular(48),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 52,
              color: Color(0xFF143C3A),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '¡Tu plan esta listo!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Tu coach IA ha preparado un plan adaptado a ti.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        // Completed steps summary
        ...state.steps.map((step) => _buildStepTile(context, step)),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(state.plan),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Ver mi plan'),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8E8),
                borderRadius: BorderRadius.circular(44),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Algo salio mal',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8E8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              error,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                _pulseController.repeat(reverse: true);
                _startGeneration();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Volver'),
            ),
          ),
        ],
      ),
    );
  }
}
