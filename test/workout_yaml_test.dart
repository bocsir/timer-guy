import 'package:flutter_test/flutter_test.dart';
import 'package:timer_guy/models/exercise.dart';
import 'package:timer_guy/models/workout.dart';
import 'package:timer_guy/services/workout_yaml.dart';

void main() {
  test('round trips a workout through YAML', () {
    final workout = Workout(
      name: 'Push Day: "Heavy"',
      description: 'Upper body\nwith plenty of rest',
      exercises: [
        Exercise(
          name: 'Push Ups',
          reps: 12,
          timeOn: 0,
          timeOff: 90,
          sets: 3,
          type: ExerciseType.reps,
        ),
        Exercise(
          name: 'Plank',
          reps: 4,
          timeOn: 30,
          timeOff: 15,
          type: ExerciseType.interval,
        ),
      ],
    );

    final decoded = workoutsFromYaml(workoutToYaml(workout)).single;

    expect(decoded.name, workout.name);
    expect(decoded.description, workout.description);
    expect(decoded.exercises, hasLength(2));

    final pushUps = decoded.exercises.first;
    expect(pushUps.name, 'Push Ups');
    expect(pushUps.type, ExerciseType.reps);
    expect(pushUps.reps, 12);
    expect(pushUps.sets, 3);
    expect(pushUps.timeOn, 0);
    expect(pushUps.timeOff, 90);

    final plank = decoded.exercises.last;
    expect(plank.name, 'Plank');
    expect(plank.type, ExerciseType.interval);
    expect(plank.reps, 4);
    expect(plank.sets, 1);
    expect(plank.timeOn, 30);
    expect(plank.timeOff, 15);
  });

  test('writes an empty exercise list', () {
    final yaml = workoutToYaml(Workout(name: 'Empty', exercises: []));

    expect(yaml, contains('exercises: []'));
    expect(workoutsFromYaml(yaml).single.exercises, isEmpty);
  });

  test('quotes scalars that YAML would otherwise reinterpret', () {
    final workout = Workout(name: 'true', exercises: []);
    final yaml = workoutToYaml(workout);

    expect(yaml, contains('name: "true"'));
    expect(workoutsFromYaml(yaml).single.name, 'true');
  });

  test('parses a list of workouts', () {
    final workouts = workoutsFromYaml('''
- name: First
  exercises: []
- name: Second
  exercises:
    - name: Run
      type: interval
      reps: 3
      time_on: 60
      time_off: 30
''');

    expect(workouts, hasLength(2));
    expect(workouts.first.name, 'First');
    expect(workouts.first.exercises, isEmpty);
    expect(workouts.last.name, 'Second');
    expect(workouts.last.exercises.single.name, 'Run');
    expect(workouts.last.exercises.single.timeOn, 60);
  });

  test('infers an interval type and accepts numeric strings', () {
    final workout = workoutsFromYaml('''
name: Legacy
description: Imported from an older file
exercises:
  - name: Plank
    reps: "4"
    time_on: 30
    time_off: 10
''').single;

    final exercise = workout.exercises.single;
    expect(workout.description, 'Imported from an older file');
    expect(exercise.type, ExerciseType.interval);
    expect(exercise.reps, 4);
    expect(exercise.timeOn, 30);
    expect(exercise.timeOff, 10);
  });

  test('accepts camelCase timing fields', () {
    final exercise = workoutsFromYaml('''
name: Camel
exercises:
  - name: Squat
    type: reps
    reps: 10
    sets: 3
    timeOff: 45
''').single.exercises.single;

    expect(exercise.type, ExerciseType.reps);
    expect(exercise.sets, 3);
    expect(exercise.timeOff, 45);
  });

  test('reports malformed YAML', () {
    expect(
      () => workoutsFromYaml('name: [unterminated'),
      throwsA(isA<WorkoutYamlException>()),
    );
  });

  test('requires a workout name', () {
    expect(
      () => workoutsFromYaml('exercises: []'),
      throwsA(
        isA<WorkoutYamlException>().having(
          (error) => error.message,
          'message',
          contains('"name" is required'),
        ),
      ),
    );
  });

  test('rejects unknown exercise types', () {
    expect(
      () => workoutsFromYaml('''
name: Bad
exercises:
  - name: Mystery
    type: heavy
    reps: 1
'''),
      throwsA(
        isA<WorkoutYamlException>().having(
          (error) => error.message,
          'message',
          contains('unknown exercise type'),
        ),
      ),
    );
  });

  test('rejects non-positive reps and sets', () {
    expect(
      () => workoutsFromYaml('''
name: Bad
exercises:
  - name: Nothing
    type: reps
    reps: 0
    sets: 3
'''),
      throwsA(isA<WorkoutYamlException>()),
    );

    expect(
      () => workoutsFromYaml('''
name: Bad
exercises:
  - name: Nothing
    type: reps
    reps: 5
    sets: 0
'''),
      throwsA(isA<WorkoutYamlException>()),
    );
  });

  test('rejects non-numeric reps', () {
    expect(
      () => workoutsFromYaml('''
name: Bad
exercises:
  - name: Nothing
    type: reps
    reps: lots
'''),
      throwsA(
        isA<WorkoutYamlException>().having(
          (error) => error.message,
          'message',
          contains('must be a whole number'),
        ),
      ),
    );
  });
}
