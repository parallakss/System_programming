#include <stdio.h>
#include <stdint.h>

// Объявления функций из ассемблера
extern void* queue_init(uint64_t capacity);
extern int queue_push_back(void* queue, uint64_t value);
extern uint64_t queue_pop_front(void* queue);
extern void queue_fill_random(void* queue, uint64_t count);
extern void queue_remove_even(void* queue);
extern uint64_t queue_count_ends_with_1(void* queue);
extern uint64_t queue_count_even(void* queue);
extern uint64_t queue_size(void* queue);
extern int queue_is_empty(void* queue);
extern void queue_destroy(void* queue);

// Вспомогательная функция для печати очереди
void print_queue(void* queue, const char* message) {
    printf("%s\n", message);
    printf("Размер очереди: %lu\n", queue_size(queue));
    printf("Элементы: ");
    
    // Создаем временную копию для обхода
    void* temp = queue_init(16);
    uint64_t size = queue_size(queue);
    
    for (uint64_t i = 0; i < size; i++) {
        uint64_t value = queue_pop_front(queue);
        printf("%lu ", value);
        queue_push_back(temp, value);
        queue_push_back(queue, value);
    }
    
    // Восстанавливаем оригинальную очередь
    for (uint64_t i = 0; i < size; i++) {
        uint64_t value = queue_pop_front(temp);
        queue_push_back(queue, value);
    }
    
    queue_destroy(temp);
    printf("\n\n");
}

int main() {
    printf("=== Демонстрация работы очереди на ассемблере ===\n\n");
    
    // Инициализация очереди
    void* queue = queue_init(8);
    if (!queue) {
        printf("Ошибка инициализации очереди!\n");
        return 1;
    }
    printf("1. Очередь инициализирована\n");
    print_queue(queue, "Состояние очереди:");
    
    // Добавление элементов в конец
    printf("2. Добавляем элементы: 10, 21, 30, 41, 52\n");
    queue_push_back(queue, 10);
    queue_push_back(queue, 21);
    queue_push_back(queue, 30);
    queue_push_back(queue, 41);
    queue_push_back(queue, 52);
    print_queue(queue, "После добавления элементов:");
    
    // Подсчет четных чисел
    uint64_t even_count = queue_count_even(queue);
    printf("3. Количество четных чисел: %lu\n\n", even_count);
    
    // Подсчет чисел, оканчивающихся на 1
    uint64_t ends_with_1_count = queue_count_ends_with_1(queue);
    printf("4. Количество чисел, оканчивающихся на 1: %lu\n\n", ends_with_1_count);
    
    // Удаление из начала
    printf("5. Удаляем элементы из начала:\n");
    for (int i = 0; i < 2; i++) {
        uint64_t value = queue_pop_front(queue);
        printf("   Извлечено: %lu\n", value);
    }
    print_queue(queue, "После удаления двух элементов:");
    
    // Заполнение случайными числами
    printf("6. Заполняем очередь 5 случайными числами\n");
    queue_fill_random(queue, 5);
    print_queue(queue, "После заполнения случайными числами:");
    
    // Подсчеты после заполнения случайными числами
    even_count = queue_count_even(queue);
    ends_with_1_count = queue_count_ends_with_1(queue);
    printf("7. Статистика после случайного заполнения:\n");
    printf("   Четных чисел: %lu\n", even_count);
    printf("   Чисел, оканчивающихся на 1: %lu\n\n", ends_with_1_count);
    
    // Удаление четных чисел
    printf("8. Удаляем все четные числа (нечетные добавляются обратно)\n");
    queue_remove_even(queue);
    print_queue(queue, "После удаления четных чисел:");
    
    // Финальная статистика
    even_count = queue_count_even(queue);
    ends_with_1_count = queue_count_ends_with_1(queue);
    printf("9. Финальная статистика:\n");
    printf("   Четных чисел: %lu\n", even_count);
    printf("   Чисел, оканчивающихся на 1: %lu\n\n", ends_with_1_count);
    
    // Очистка памяти
    queue_destroy(queue);
    printf("10. Память освобождена\n");
    
    return 0;
}